import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// The url follows the active tab when two AutoTabsRouter tabs share a parent
// route.
// https://github.com/Milad-Akarie/auto_route_library/issues/1874
// Headless test:
// auto_route/test/nested_tabs_router/tab_shared_parent_url_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: /dashboard has the children tests (a nested router holding test1
  // and test2) and test3; its tabs are [Test1Route(), Test2Route(),
  // Test3Route()]. Tap 'First', 'Second', then 'First' again.
  // Should: the url is /dashboard/tests/test1, in the browser's address bar
  // too on web.
  testWidgets(
    'the url follows the active tab when two tabs share a parent route',
    (tester) async {
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
      await pumpRouterApp(tester, router);
      expect(router.urlState.url, '/dashboard/test3');

      Future<void> openTab(String label, String text, String url) async {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(find.text(text), findsOneWidget);
        expect(router.urlState.url, url);
        await expectBrowserUrl(url);
      }

      await openTab('First', _Test1Route.name, '/dashboard/tests/test1');
      await openTab('Second', _Test2Route.name, '/dashboard/tests/test2');
      await openTab('First', _Test1Route.name, '/dashboard/tests/test1');
      await openTab('Third', _Test3Route.name, '/dashboard/test3');
    },
  );
}

class _DashboardRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_DashboardRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => AutoTabsRouter(
      routes: const [_Test1Route(), _Test2Route(), _Test3Route()],
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    for (final (index, label) in [
                      'First',
                      'Second',
                      'Third',
                    ].indexed)
                      TextButton(
                        onPressed: () => tabsRouter.setActiveIndex(index),
                        child: Text(label),
                      ),
                  ],
                ),
                Expanded(child: child),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _TestsRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_TestsRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const AutoRouter());
}

class _Test1Route extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_Test1Route';
  static PageInfo page = PageInfo(name, builder: (_) => const Text(name));
}

class _Test2Route extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_Test2Route';
  static PageInfo page = PageInfo(name, builder: (_) => const Text(name));
}

class _Test3Route extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_Test3Route';
  static PageInfo page = PageInfo(name, builder: (_) => const Text(name));
}
