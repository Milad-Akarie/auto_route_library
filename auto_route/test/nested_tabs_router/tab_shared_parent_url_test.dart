import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // Reproduces https://github.com/Milad-Akarie/auto_route_library/issues/1874
  // Steps: /dashboard has the children tests (a nested router holding test1
  // and test2) and test3. Its AutoTabsRouter has routes [Test1Route(),
  // Test2Route(), Test3Route()], so the first two tabs are both the tests
  // route, each with its own nested router. Open the first tab, the second,
  // then the first again.
  // Happens: the url stays /dashboard/tests/test2 while the first tab shows.
  // Should: the url is /dashboard/tests/test1.
  testWidgets('the url follows the active tab when two tabs share a parent route', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        RedirectRoute(path: '/', redirectTo: '/dashboard'),
        AutoRoute(
          page: _DashboardRoute.page,
          path: '/dashboard',
          children: [
            RedirectRoute(path: '', redirectTo: 'test3'),
            AutoRoute(
              page: _TestsRoute.page,
              path: 'tests',
              children: [
                AutoRoute(page: _Test1Route.page, path: 'test1'),
                AutoRoute(page: _Test2Route.page, path: 'test2'),
              ],
            ),
            AutoRoute(page: _Test3Route.page, path: 'test3'),
          ],
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    expect(router.urlState.url, '/dashboard/test3');
    final tabsRouter = router.innerRouterOf<TabsRouter>(_DashboardRoute.name)!;

    Future<void> openTab(int index, String text, String url) async {
      tabsRouter.setActiveIndex(index);
      await tester.pumpAndSettle();
      expect(find.text(text), findsOneWidget);
      expect(router.urlState.url, url);
    }

    await openTab(0, _Test1Route.name, '/dashboard/tests/test1');
    await openTab(1, _Test2Route.name, '/dashboard/tests/test2');
    await openTab(0, _Test1Route.name, '/dashboard/tests/test1');
    await openTab(2, _Test3Route.name, '/dashboard/test3');
    await openTab(0, _Test1Route.name, '/dashboard/tests/test1');
  });
}

class _DashboardRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_DashboardRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => const AutoTabsRouter(routes: [_Test1Route(), _Test2Route(), _Test3Route()]),
  );
}

class _TestsRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_TestsRoute';
  static final PageInfo page = PageInfo(name, builder: (_) => const AutoRouter());
}

class _Test1Route extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_Test1Route';
  static final PageInfo page = PageInfo(name, builder: (_) => const Text(name));
}

class _Test2Route extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_Test2Route';
  static final PageInfo page = PageInfo(name, builder: (_) => const Text(name));
}

class _Test3Route extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_Test3Route';
  static final PageInfo page = PageInfo(name, builder: (_) => const Text(name));
}
