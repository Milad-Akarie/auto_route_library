import 'package:test/test.dart';

import 'support/generate.dart';

void main() {
  test('generates a route for a page that compiles in a part file', () async {
    final result = await generateRouter({
      'lib/router.dart': '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

import 'home_page.dart';

part 'router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [AutoRoute(page: HomeRoute.page)];
}
''',
      'lib/home_page.dart': '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(title);
}
''',
    });
    expect(result.errors, isEmpty);
    expect(result.compileErrors, isEmpty);
    expect(result.source, contains('HomeRoute({Key? key, required String title'));
  });

  test('generates a route that compiles in its own library', () async {
    final result = await generateRouter({'lib/home_page.dart': _page('HomePage')});
    expect(result.errors, isEmpty);
    expect(result.compileErrors, isEmpty);
    expect(result.source, contains("import 'package:app/home_page.dart' as _i"));
  });
}

String _page(String name) => '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

@RoutePage()
class $name extends StatelessWidget {
  const $name({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';
