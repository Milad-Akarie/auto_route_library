import 'package:test/test.dart';

import 'support/generate.dart';

const _loginPage = '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('Login'));
}
''';

void main() {
  // #2326 (also #2052, #1804): pages annotated with `@RoutePage()` in another
  // package are not added to the app's generated router. By design, a
  // router only collects the pages of its own package. The README's
  // "Including Micro/External Packages" is the supported way: the package
  // generates its own routes with its own `@AutoRouterConfig`, and the app
  // lists them in its routes.
  group('pages from another package (#2326)', () {
    test('are not collected by the app router', () async {
      final result = await generateRouter({
        'skeleton|lib/src/router/login_page.dart': _loginPage,
        'skeleton|lib/skeleton.dart': "library skeleton;\n\nexport 'src/router/login_page.dart';\n",
        'lib/home_page.dart': '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''',
      });
      expect(result.errors, isEmpty);
      expect(result.source, contains('class HomeRoute'));
      expect(result.source, isNot(contains('LoginRoute')));
    });

    test("are routed through the package's own router", () async {
      final result = await generateRouter({
        'skeleton|lib/src/router/login_page.dart': _loginPage,
        'skeleton|lib/skeleton_router.dart': '''
import 'package:auto_route/auto_route.dart';

import 'skeleton_router.gr.dart';

export 'skeleton_router.gr.dart';

@AutoRouterConfig()
class SkeletonRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [AutoRoute(path: '/login', page: LoginRoute.page)];
}
''',
        'lib/router.dart': '''
import 'package:auto_route/auto_route.dart';
import 'package:skeleton/skeleton_router.dart';

import 'router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  final skeletonRouter = SkeletonRouter();

  @override
  List<AutoRoute> get routes => [
        AutoRoute(path: '/sign-in', page: LoginRoute.page),
        ...skeletonRouter.routes,
      ];
}
''',
        'lib/home_page.dart': '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''',
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
    });
  });
}
