import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  late RootStackRouter router;
  late TabsRouter tabsRouter;

  Future<void> pumpDashboard(WidgetTester tester, {String? initialLink}) async {
    router = RootStackRouter.build(
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
    if (initialLink == null) {
      await pumpRouterConfigApp(tester, router.config());
    } else {
      await pumpRouterApp(tester, router, initialLink: initialLink);
    }
    tabsRouter = router.innerRouterOf<TabsRouter>(_DashboardRoute.name)!;
  }

  // The pages of each tab's nested router; '-' for a tab without one.
  List<String> tabStacks() => [
    for (var i = 0; i < tabsRouter.pageCount; i++)
      tabsRouter.stackRouterOfIndex(i)?.stack.map((p) => p.name).join(', ') ??
          '-',
  ];

  // Found while settling
  // https://github.com/Milad-Akarie/auto_route_library/issues/1874; no upstream report of its own.
  // Steps: /dashboard has the children tests (a nested router holding test1
  // and test2) and test3. Its AutoTabsRouter has routes [Test1Route(),
  // Test2Route(), Test3Route()], so the first two tabs are both the tests
  // route, each with its own nested router. Open the first two tabs, then the
  // third, then navigate to Test2Route.
  // Happened: the first tab opened, still on Test1Route, at
  // /dashboard/tests/test1: the tab was looked up by route name, which found
  // the first tests tab, and its nested router too, which found the second.
  // Should: the second tab opens, on Test2Route, and the first is left as it
  // was.
  testWidgets(
    'navigate() to the second of two tabs sharing a route opens that tab',
    (tester) async {
      await pumpDashboard(tester);
      for (final index in [0, 1, 2]) {
        tabsRouter.setActiveIndex(index);
        await tester.pumpAndSettle();
      }

      unawaited(router.navigate(const _Test2Route()));
      await tester.pumpAndSettle();
      expect(tabsRouter.activeIndex, 1);
      expect(find.text(_Test2Route.name), findsOneWidget);
      expect(router.urlState.url, '/dashboard/tests/test2');
      expect(tabStacks(), [_Test1Route.name, _Test2Route.name, '-']);
    },
  );

  // Steps: open the app through DeepLink.path, open all three tabs, then
  // navigate to Test2Route naming a result type.
  // Happened: the page holding the tabs was built again with that type, and
  // canUpdate compared the two by runtimeType, so the tabs started over.
  // Should: the second tab opens, and the tabs keep their pages.
  for (final (type, navigate) in <(String, Future<Object?> Function())>[
    ('void', () => router.navigate<void>(const _Test2Route())),
    ('bool', () => router.navigate<bool>(const _Test2Route())),
  ]) {
    testWidgets(
      'navigate<$type>() after a DeepLink.path start keeps the tabs',
      (tester) async {
        await pumpDashboard(tester, initialLink: '/');
        for (final index in [0, 1, 2]) {
          tabsRouter.setActiveIndex(index);
          await tester.pumpAndSettle();
        }

        navigate().ignore();
        await tester.pumpAndSettle();
        expect(tabStacks(), [_Test1Route.name, _Test2Route.name, '-']);
      },
    );
  }

  // Same steps, navigating to Test1Route.
  // Happened: the first tab opened, but Test1Route was also pushed onto the
  // second tab's nested router.
  testWidgets(
    'navigate() to the first of two tabs sharing a route leaves the second as '
    'it was',
    (tester) async {
      await pumpDashboard(tester);
      for (final index in [0, 1, 2]) {
        tabsRouter.setActiveIndex(index);
        await tester.pumpAndSettle();
      }

      unawaited(router.navigate(const _Test1Route()));
      await tester.pumpAndSettle();
      expect(tabsRouter.activeIndex, 0);
      expect(find.text(_Test1Route.name), findsOneWidget);
      expect(router.urlState.url, '/dashboard/tests/test1');
      expect(tabStacks(), [_Test1Route.name, _Test2Route.name, '-']);
    },
  );

  // Steps: open the second tab, then the first, then go back, which opens
  // the url the second tab recorded, /dashboard/tests/test2.
  // Should: the second tab shows again, and the first is left as it was.
  testWidgets(
    'going back to a url of the second of two tabs sharing a route opens that '
    'tab',
    (tester) async {
      await pumpDashboard(tester);
      for (final index in [1, 0]) {
        tabsRouter.setActiveIndex(index);
        await tester.pumpAndSettle();
      }

      router.back();
      await tester.pumpAndSettle();
      expect(tabsRouter.activeIndex, 1);
      expect(find.text(_Test2Route.name), findsOneWidget);
      expect(router.urlState.url, '/dashboard/tests/test2');
      expect(tabStacks(), [_Test1Route.name, _Test2Route.name, '-']);
      // On web, back moves the browser, whose history this runner doesn't
      // keep; the integration test goes back there with the browser's back
      // button.
    },
    skip: kIsWeb,
  );
}

abstract final class _DashboardRoute {
  static const String name = '_DashboardRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => const AutoTabsRouter(
      routes: [_Test1Route(), _Test2Route(), _Test3Route()],
    ),
  );
}

abstract final class _TestsRoute {
  static const String name = '_TestsRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => const AutoRouter(),
  );
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
