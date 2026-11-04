import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// Each tab event the observer gets, as '<call> <tab> from <previous tab>'.
final _tabEvents = <String>[];

class _TabsObserver extends AutoRouterObserver {
  @override
  void didInitTabRoute(TabPageRoute route, TabPageRoute? previousRoute) =>
      _tabEvents.add('didInitTabRoute ${route.name} from ${previousRoute?.name}');

  @override
  void didChangeTabRoute(TabPageRoute route, TabPageRoute previousRoute) =>
      _tabEvents.add('didChangeTabRoute ${route.name} from ${previousRoute.name}');
}

class _Route extends PageRouteInfo<void> {
  const _Route(super.name);
}

PageInfo _tabPage(String name) => PageInfo(name, builder: (_) => Center(child: Text(name)));

const _tabs = [_Route('Tab1'), _Route('Tab2'), _Route('Tab3')];

RootStackRouter _router(Widget Function() tabsRouter) => RootStackRouter.build(
  routes: [
    AutoRoute(
      path: '/',
      page: PageInfo('TabsRoute', builder: (_) => tabsRouter()),
      children: [
        AutoRoute(path: 'tab1', page: _tabPage('Tab1')),
        AutoRoute(path: 'tab2', page: _tabPage('Tab2')),
        AutoRoute(path: 'tab3', page: _tabPage('Tab3')),
      ],
    ),
  ],
);

Future<void> _expectSwipesInitNewTabs(WidgetTester tester, RootStackRouter router) async {
  await pumpRouterConfigApp(tester, router.config(navigatorObservers: () => [_TabsObserver()]));
  final tabsRouter = router.innerRouterOf<TabsRouter>('TabsRoute')!;
  expect(_tabEvents, ['didInitTabRoute Tab1 from null']);

  // Swipes forward to the second tab, which was never opened.
  await tester.fling(find.text('Tab1'), const Offset(-400, 0), 1000);
  await tester.pumpAndSettle();
  expect(tabsRouter.activeIndex, 1);
  expect(_tabEvents.last, 'didInitTabRoute Tab2 from Tab1');

  // Swipes back to the first tab, already opened.
  await tester.fling(find.text('Tab2'), const Offset(400, 0), 1000);
  await tester.pumpAndSettle();
  expect(tabsRouter.activeIndex, 0);
  expect(_tabEvents.last, 'didChangeTabRoute Tab1 from Tab2');

  // Swipes forward to the second tab again: opened before, so a change.
  await tester.fling(find.text('Tab1'), const Offset(-400, 0), 1000);
  await tester.pumpAndSettle();
  expect(tabsRouter.activeIndex, 1);
  expect(_tabEvents.last, 'didChangeTabRoute Tab2 from Tab1');
}

void main() {
  setUp(_tabEvents.clear);

  // Found while settling the observer issues; no upstream report.
  // Steps: AutoTabsRouter.pageView with three tabs and an AutoRouterObserver.
  // Swipe forward to the second tab, which was never opened.
  // Happened: the observer got didChangeTabRoute, never didInitTabRoute: the
  // page view loads the neighbor tab during the drag without telling
  // observers, so when the swipe makes it active it looks already opened.
  // Should: a tab's first opening fires didInitTabRoute, as a tap does.
  testWidgets('Swiping AutoTabsRouter.pageView to a tab never opened fires didInitTabRoute', (tester) async {
    await _expectSwipesInitNewTabs(tester, _router(() => AutoTabsRouter.pageView(routes: _tabs)));
  });

  // Same steps with AutoTabsRouter.tabBar, whose tab view loads the neighbor
  // tab during the drag the same way.
  testWidgets('Swiping AutoTabsRouter.tabBar to a tab never opened fires didInitTabRoute', (tester) async {
    await _expectSwipesInitNewTabs(
      tester,
      _router(() => AutoTabsRouter.tabBar(routes: _tabs, builder: (context, child, controller) => child)),
    );
  });
}
