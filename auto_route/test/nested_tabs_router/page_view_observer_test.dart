import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// Each tab event the observer gets, as '<call> <tab> from <previous tab>'.
final _tabEvents = <String>[];

class _TabsObserver extends AutoRouterObserver {
  @override
  void didInitTabRoute(TabPageRoute route, TabPageRoute? previousRoute) =>
      _tabEvents.add(
        'didInitTabRoute ${route.name} from ${previousRoute?.name ?? 'null'}',
      );

  @override
  void didChangeTabRoute(TabPageRoute route, TabPageRoute previousRoute) =>
      _tabEvents.add(
        'didChangeTabRoute ${route.name} from ${previousRoute.name}',
      );
}

class _Route extends PageRouteInfo<void> {
  const new(super.name);
}

PageInfo _tabPage(String name) =>
    .new(name, builder: (_) => Center(child: Text(name)));

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/2044
  // Steps: AutoTabsRouter.pageView with three tabs and an observer. Swipe to
  // the second tab, then swipe back to the first one.
  // Happened: swiping from a higher page index to a lower one fired no
  // didChangeTabRoute, so a bottom navigation bar built from it kept the old tab.
  // Should: each swipe fires didChangeTabRoute with the tab it left.
  testWidgets(
    'Swiping AutoTabsRouter.pageView back to a lower tab fires didChangeTabRoute',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: PageInfo(
              'TabsRoute',
              builder: (_) => const AutoTabsRouter.pageView(
                routes: [_Route('Tab1'), _Route('Tab2'), _Route('Tab3')],
              ),
            ),
            children: [
              AutoRoute(path: 'tab1', page: _tabPage('Tab1')),
              AutoRoute(path: 'tab2', page: _tabPage('Tab2')),
              AutoRoute(path: 'tab3', page: _tabPage('Tab3')),
            ],
          ),
        ],
      );
      await pumpRouterConfigApp(
        tester,
        router.config(navigatorObservers: () => [_TabsObserver()]),
      );
      final tabsRouter = router.innerRouterOf<TabsRouter>('TabsRoute')!;
      _tabEvents.clear();

      await tester.fling(find.text('Tab1'), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();
      expect(tabsRouter.activeIndex, 1);

      await tester.fling(find.text('Tab2'), const Offset(400, 0), 1000);
      await tester.pumpAndSettle();
      expect(tabsRouter.activeIndex, 0);
      expect(_tabEvents.lastOrNull, 'didChangeTabRoute Tab1 from Tab2');
    },
  );
}
