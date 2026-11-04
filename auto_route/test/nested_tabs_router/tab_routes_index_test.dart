import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  _TabsKind.values.forEach(_runIndexTests);
}

void _runIndexTests(_TabsKind kind) {
  Future<RootStackRouter> pumpTabs(WidgetTester tester, List<PageRouteInfo> routes, {String initialLink = '/'}) async {
    _tabsKind = kind;
    _routesNotifier.value = routes;
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: _TabsHostRoute.page,
          path: '/',
          children: [
            AutoRoute(page: _FirstTabRoute.page, path: 'first', initial: true),
            AutoRoute(page: _SecondTabRoute.page, path: 'second'),
          ],
        ),
      ],
    );
    // An AutoRouterObserver hears about tab changes; it reads the tab routes by index.
    await pumpRouterApp(tester, router, initialLink: initialLink, observers: () => [AutoRouterObserver()]);
    return router;
  }

  // Reproduces https://github.com/Milad-Akarie/auto_route_library/issues/2308
  // Steps: an AutoTabsRouter has routes [first, second] and an
  // AutoRouterObserver. Open the second tab, then rebuild with [first] only.
  // Happens: RangeError in _didChangeTabRoute, which reads the old active
  // index 1 in the new one-tab routes.
  // Should: the first tab shows.
  testWidgets('${kind.name}: removing the active last tab shows the first tab', (tester) async {
    final router = await pumpTabs(tester, const [_FirstTabRoute(), _SecondTabRoute()]);
    router.innerRouterOf<TabsRouter>(_TabsHostRoute.name)!.setActiveIndex(1);
    await tester.pumpAndSettle();
    expect(find.text(_SecondTabRoute.name), findsOneWidget);

    _routesNotifier.value = const [_FirstTabRoute()];
    await tester.pumpAndSettle();
    expect(find.text(_FirstTabRoute.name), findsOneWidget);
    expect(router.innerRouterOf<TabsRouter>(_TabsHostRoute.name)!.activeIndex, 0);
  });

  // Same as above, but the app opens on the second tab, so the first tab
  // has never been shown when it becomes the active tab.
  testWidgets('${kind.name}: removing the active tab shows a tab never opened before', (tester) async {
    await pumpTabs(tester, const [_FirstTabRoute(), _SecondTabRoute()], initialLink: '/second');
    expect(find.text(_SecondTabRoute.name), findsOneWidget);

    _routesNotifier.value = const [_FirstTabRoute()];
    await tester.pumpAndSettle();
    expect(find.text(_FirstTabRoute.name), findsOneWidget);
  });

  // The same RangeError when the routes grow: with [first] active, a rebuild
  // with [second, first] moves the active tab to index 1, past the old routes.
  testWidgets('${kind.name}: adding a tab before the active tab keeps it shown', (tester) async {
    final router = await pumpTabs(tester, const [_FirstTabRoute()]);
    expect(find.text(_FirstTabRoute.name), findsOneWidget);

    _routesNotifier.value = const [_SecondTabRoute(), _FirstTabRoute()];
    await tester.pumpAndSettle();
    expect(find.text(_FirstTabRoute.name), findsOneWidget);
    expect(router.innerRouterOf<TabsRouter>(_TabsHostRoute.name)!.activeIndex, 1);
  });
}

enum _TabsKind { indexedStack, pageView, tabBar, builder }

_TabsKind _tabsKind = .indexedStack;

final _routesNotifier = ValueNotifier<List<PageRouteInfo>>(const []);

class _TabsHostRoute extends PageRouteInfo<void> {
  const _TabsHostRoute() : super(name);

  static const String name = '_TabsHostRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => ValueListenableBuilder<List<PageRouteInfo>>(
      valueListenable: _routesNotifier,
      builder: (context, routes, _) => switch (_tabsKind) {
        .indexedStack => AutoTabsRouter(routes: routes),
        .pageView => AutoTabsRouter.pageView(routes: routes),
        .tabBar => AutoTabsRouter.tabBar(routes: routes),
        .builder => AutoTabsRouter.builder(
          routes: routes,
          builder: (context, children, tabsRouter) => IndexedStack(index: tabsRouter.activeIndex, children: children),
        ),
      },
    ),
  );
}

class _FirstTabRoute extends PageRouteInfo<void> {
  const _FirstTabRoute() : super(name);

  static const String name = '_FirstTabRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text(name)));
}

class _SecondTabRoute extends PageRouteInfo<void> {
  const _SecondTabRoute() : super(name);

  static const String name = '_SecondTabRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text(name)));
}
