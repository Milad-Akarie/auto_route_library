import 'package:test/test.dart';

import 'support/generate.dart';

const _kHomePage = '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';

void main() {
  // #1686: setting `build_extensions` on the router builder to write the
  // router somewhere else failed every build with "Configured
  // build_extensions should be a map from inputs to outputs.", even for a
  // valid map: the builder rejected the option whatever it held.
  group('build_extensions moves the generated router (#1686)', () {
    const moved = {
      'build_extensions': {'^lib/{{}}.dart': 'lib/generated/{{}}.gr.dart'},
    };

    test('as a part of the router', () async {
      final result = await generateRouter(
        {
          'lib/home_page.dart': _kHomePage,
          'lib/router.dart': '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

import 'home_page.dart';

part 'generated/router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [AutoRoute(page: HomeRoute.page)];
}
''',
        },
        routerOptions: moved,
        outputPath: 'lib/generated/router.gr.dart',
      );
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      expect(result.source, contains("part of '../router.dart';"));
    });

    test('as a library of its own', () async {
      final result = await generateRouter(
        {
          'lib/home_page.dart': _kHomePage,
          'lib/router.dart': '''
import 'package:auto_route/auto_route.dart';

import 'generated/router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [AutoRoute(page: HomeRoute.page)];
}
''',
        },
        routerOptions: moved,
        outputPath: 'lib/generated/router.gr.dart',
      );
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      expect(result.source, contains('class HomeRoute'));
    });

    test('and an output that is not Dart is refused', () async {
      expect(
        () => generateRouter(
          {'lib/home_page.dart': _kHomePage},
          routerOptions: {
            'build_extensions': {'^lib/{{}}.dart': 'lib/generated/{{}}.gr.txt'},
          },
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('ending with `.dart`'),
          ),
        ),
      );
    });
  });
}
