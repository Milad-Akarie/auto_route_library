import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  for (final kind in _TabsKind.values) {
    // Guards https://github.com/Milad-Akarie/auto_route_library/issues/2189
    // Steps: an AutoTabsRouter.pageView has routes [nestedHost, if (extra)
    // extra, second]; nestedHost holds a nested router. Open the nested
    // second page, add the extra route, then do what re-tapping the active
    // tab does: tabsRouter.innerRouterOf<StackRouter>(current.name)
    // ?.popUntilRoot().
    // Reported: innerRouterOf returns null after the routes change, with the
    // page-view kind only.
    // Should: it returns the nested router, which pops to its first page.
    testWidgets('${kind.name}: innerRouterOf finds the tab\'s nested router after the routes change', (tester) async {
      addTearDown(() => _extraNotifier.value = false);
      _tabsKind = kind;
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            page: _HostRoute.page,
            path: '/',
            initial: true,
            children: [
              AutoRoute(
                page: _NestedHostRoute.page,
                path: 'nested',
                initial: true,
                children: [
                  AutoRoute(page: _NestedFirstRoute.page, path: '', initial: true),
                  AutoRoute(page: _NestedSecondRoute.page, path: 'second'),
                ],
              ),
              AutoRoute(page: _ExtraRoute.page, path: 'extra'),
              AutoRoute(page: _SecondRoute.page, path: 'second'),
            ],
          ),
        ],
      );
      await pumpRouterConfigApp(tester, router.config());
      final tabsRouter = router.innerRouterOf<TabsRouter>(_HostRoute.name)!;
      tabsRouter.innerRouterOf<StackRouter>(_NestedHostRoute.name)!.push(const _NestedSecondRoute());
      await tester.pumpAndSettle();
      expect(find.text(_NestedSecondRoute.name), findsOneWidget);

      _extraNotifier.value = true;
      await tester.pumpAndSettle();
      final innerRouter = tabsRouter.innerRouterOf<StackRouter>(tabsRouter.current.name);
      expect(innerRouter, isNotNull);
      expect(innerRouter!.canPop(), isTrue);
      innerRouter.popUntilRoot();
      await tester.pumpAndSettle();
      expect(find.text(_NestedFirstRoute.name), findsOneWidget);
      expect(find.text(_NestedSecondRoute.name), findsNothing);
    });
  }
}

enum _TabsKind { indexedStack, pageView, tabBar, builder }

_TabsKind _tabsKind = _TabsKind.indexedStack;

final _extraNotifier = ValueNotifier<bool>(false);

class _HostRoute extends PageRouteInfo<void> {
  const _HostRoute() : super(name);

  static const String name = '_HostRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => ValueListenableBuilder<bool>(
      valueListenable: _extraNotifier,
      builder: (context, extra, _) {
        final routes = [const _NestedHostRoute(), if (extra) const _ExtraRoute(), const _SecondRoute()];
        return switch (_tabsKind) {
          _TabsKind.indexedStack => AutoTabsRouter(routes: routes),
          _TabsKind.pageView => AutoTabsRouter.pageView(routes: routes),
          _TabsKind.tabBar => AutoTabsRouter.tabBar(routes: routes),
          _TabsKind.builder => AutoTabsRouter.builder(
            routes: routes,
            builder: (context, children, tabsRouter) => IndexedStack(index: tabsRouter.activeIndex, children: children),
          ),
        };
      },
    ),
  );
}

class _NestedHostRoute extends PageRouteInfo<void> {
  const _NestedHostRoute() : super(name);

  static const String name = '_NestedHostRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const AutoRouter());
}

class _NestedFirstRoute extends PageRouteInfo<void> {
  const _NestedFirstRoute() : super(name);

  static const String name = '_NestedFirstRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text(name)));
}

class _NestedSecondRoute extends PageRouteInfo<void> {
  const _NestedSecondRoute() : super(name);

  static const String name = '_NestedSecondRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text(name)));
}

class _ExtraRoute extends PageRouteInfo<void> {
  const _ExtraRoute() : super(name);

  static const String name = '_ExtraRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text(name)));
}

class _SecondRoute extends PageRouteInfo<void> {
  const _SecondRoute() : super(name);

  static const String name = '_SecondRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text(name)));
}
