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

  // A router library outside `lib/` (in `integration_test/`) with pages
  // outside `lib/` got `import 'asset:app/integration_test/...'`, which the
  // analyzer accepts but a Flutter build rejects. Pages under `lib/` keep
  // their `package:` import.
  group('a router outside lib/', () {
    const router = '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

import 'home_page.dart';
import 'pages/detail_page.dart';
import '../lib/shared_page.dart';

import 'router.gr.dart';

@AutoRouterConfig(generateForDir: ['integration_test', 'lib'])
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: HomeRoute.page),
    AutoRoute(page: DetailRoute.page),
    AutoRoute(page: SharedRoute.page),
  ];
}
''';

    test('imports its pages by relative path and keeps package: for lib/', () async {
      final result = await generateRouter({
        'integration_test/router.dart': router,
        'integration_test/home_page.dart': _page('HomePage'),
        'integration_test/pages/detail_page.dart': _page('DetailPage'),
        'lib/shared_page.dart': _page('SharedPage'),
      }, routerPath: 'integration_test/router.dart');
      expect(result.errors, isEmpty);
      expect(result.source, isNot(contains('asset:')));
      expect(result.source, contains("import 'home_page.dart' as _i"));
      expect(result.source, contains("import 'pages/detail_page.dart' as _i"));
      expect(result.source, contains("import 'package:app/shared_page.dart' as _i"));
    });
  });

  // #1870: a page whose name `replaceInRouteName` does not change, such as
  // `CostsTab`, got a route with the page's own name. In a part file that
  // route is declared in the library that imports the page, so it shadowed
  // the page and the build left a router that does not compile.
  group('a page the default replacement does not rename (#1870)', () {
    String router({required bool part}) =>
        '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

import 'costs_tab.dart';
${part ? "\npart 'router.gr.dart';\n" : ''}
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [];
}
''';

    test('fails the build with the fix in a part file', () async {
      final result = await generateRouter({
        'lib/router.dart': router(part: true),
        'lib/costs_tab.dart': _page('CostsTab'),
      });
      expect(result.errors, hasLength(1));
      expect(result.errors.join(), allOf(contains('CostsTab'), contains("@RoutePage(name: 'CostsTabRoute')")));
    });

    test('compiles in a part file once the page is named', () async {
      final result = await generateRouter({
        'lib/router.dart': router(part: true),
        'lib/costs_tab.dart': _page('CostsTab').replaceFirst('@RoutePage()', "@RoutePage(name: 'CostsTabRoute')"),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      expect(result.source, contains('class CostsTabRoute extends'));
    });

    test('compiles in its own library, where the page is imported with a prefix', () async {
      final result = await generateRouter({
        'lib/router.dart': router(part: false),
        'lib/costs_tab.dart': _page('CostsTab'),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      expect(result.source, contains('class CostsTab extends'));
    });
  });
}

String _page(String name) =>
    '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

@RoutePage()
class $name extends StatelessWidget {
  const $name({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';
