import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// navigate() to one of two AutoTabsRouter tabs sharing a route opens that tab
// and leaves the other as it was. Going back on web, the browser's back button,
// does the same.
// Found while settling https://github.com/Milad-Akarie/auto_route_library/issues/1874.
// Headless test: auto_route/test/nested_tabs_router/tab_shared_route_navigate_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('tab shared route navigate', () {
    RootStackRouter buildRouter() => .build(
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

    // The pages of each tab's nested router; '-' for a tab without one.
    List<String> tabStacks(RootStackRouter router) {
      final tabsRouter = router.innerRouterOf<TabsRouter>(
        _DashboardRoute.name,
      )!;
      return [
        for (var i = 0; i < tabsRouter.pageCount; i++)
          tabsRouter
                  .stackRouterOfIndex(i)
                  ?.stack
                  .map((p) => p.name)
                  .join(', ') ??
              '-',
      ];
    }

    // Steps: /dashboard has the children tests (a nested router holding test1
    // and test2) and test3; its tabs are [Test1Route(), Test2Route(),
    // Test3Route()]. Tap 'First', 'Second', 'Third', then navigate to
    // Test2Route, tap 'Third' again and navigate to Test1Route.
    // Should: each navigate opens the tab of its route, and the other tab keeps
    // its one page.
    testWidgets(
      'navigate() opens the tab of its route when two tabs share a route',
      (tester) async {
        final router = buildRouter();
        await pumpRouterApp(tester, router);
        for (final label in ['First', 'Second', 'Third']) {
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
        }

        router.navigate(const _Test2Route()).ignore();
        await tester.pumpAndSettle();
        expect(find.text(_Test2Route.name), findsOneWidget);
        expect(router.urlState.url, '/dashboard/tests/test2');
        await expectBrowserUrl('/dashboard/tests/test2');
        expect(tabStacks(router), [_Test1Route.name, _Test2Route.name, '-']);

        await tester.tap(find.text('Third'));
        await tester.pumpAndSettle();
        router.navigate(const _Test1Route()).ignore();
        await tester.pumpAndSettle();
        expect(find.text(_Test1Route.name), findsOneWidget);
        expect(router.urlState.url, '/dashboard/tests/test1');
        await expectBrowserUrl('/dashboard/tests/test1');
        expect(tabStacks(router), [_Test1Route.name, _Test2Route.name, '-']);
      },
    );

    // Steps: tap 'Second', then 'First', then go back: the browser's back
    // button on web, router.back() elsewhere.
    // Should: the second tab shows again, at /dashboard/tests/test2.
    testWidgets(
      'going back to the second of two tabs sharing a route opens that tab',
      (tester) async {
        final router = buildRouter();
        await pumpRouterAppWithConfig(tester, router);
        for (final label in ['Second', 'First']) {
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
        }

        if (kIsWeb) {
          pressBrowserBack();
          await expectBrowserUrl('/dashboard/tests/test2');
        } else {
          router.back();
        }
        await tester.pumpAndSettle();
        expect(find.text(_Test2Route.name), findsOneWidget);
        expect(router.urlState.url, '/dashboard/tests/test2');
        expect(tabStacks(router), [_Test1Route.name, _Test2Route.name, '-']);
      },
    );
  });
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
