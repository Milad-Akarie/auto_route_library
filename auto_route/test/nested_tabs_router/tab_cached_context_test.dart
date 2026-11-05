import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  for (final kind in _TabsKind.values) {
    // Guards https://github.com/Milad-Akarie/auto_route_library/issues/2252
    // Steps: the AutoTabsRouter's builder keeps its context. From the second
    // tab's page, call AutoTabsRouter.of(keptContext).setActiveIndex(0).
    // Reported: nothing happens, on 10.1.2 and not on 9.2.2.
    // Should: the first tab shows.
    testWidgets('${kind.name}: setActiveIndex through the builder context kept by a tab page opens the tab', (
      tester,
    ) async {
      _tabsKind = kind;
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            page: _TabsHostRoute.page,
            path: '/',
            initial: true,
            children: [
              AutoRoute(page: _FirstTabRoute.page, path: 'first'),
              AutoRoute(page: _SecondTabRoute.page, path: 'second'),
            ],
          ),
        ],
      );
      await pumpRouterConfigApp(tester, router.config());
      AutoTabsRouter.of(_keptContext).setActiveIndex(1);
      await tester.pumpAndSettle();
      expect(find.text(_SecondTabRoute.name), findsOneWidget);

      await tester.tap(find.text('Back to the first tab'));
      await tester.pumpAndSettle();
      expect(find.text(_FirstTabRoute.name), findsOneWidget);
      expect(router.innerRouterOf<TabsRouter>(_TabsHostRoute.name)!.activeIndex, 0);
    });
  }
}

enum _TabsKind { indexedStack, pageView, tabBar, builder }

_TabsKind _tabsKind = .indexedStack;

// The context of the AutoTabsRouter's builder, kept for the tab pages.
late BuildContext _keptContext;

abstract final class _TabsHostRoute {
  static const String name = '_TabsHostRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) {
      const routes = [_FirstTabRoute(), _SecondTabRoute()];
      return switch (_tabsKind) {
        .indexedStack => AutoTabsRouter(
          routes: routes,
          builder: (context, child) {
            _keptContext = context;
            return child;
          },
        ),
        .pageView => AutoTabsRouter.pageView(
          routes: routes,
          builder: (context, child, _) {
            _keptContext = context;
            return child;
          },
        ),
        .tabBar => AutoTabsRouter.tabBar(
          routes: routes,
          builder: (context, child, _) {
            _keptContext = context;
            return child;
          },
        ),
        .builder => AutoTabsRouter.builder(
          routes: routes,
          builder: (context, children, tabsRouter) {
            _keptContext = context;
            return IndexedStack(index: tabsRouter.activeIndex, children: children);
          },
        ),
      };
    },
  );
}

class _FirstTabRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_FirstTabRoute';
  static final PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text(name)));
}

class _SecondTabRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_SecondTabRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => Scaffold(
      body: Column(
        children: [
          const Text(name),
          TextButton(
            onPressed: () => AutoTabsRouter.of(_keptContext).setActiveIndex(0),
            child: const Text('Back to the first tab'),
          ),
        ],
      ),
    ),
  );
}
