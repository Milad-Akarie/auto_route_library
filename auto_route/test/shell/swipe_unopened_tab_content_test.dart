import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/flutter/flutter/issues/150837
// Setup: a page holds swipeable tabs, each tab with its own stack, none but
// the first opened yet.
// Steps: drag the tab view toward the second tab, then let go.
// Should: the second tab's page shows while dragging and after the
// swipe, never blank space.
void main() {
  for (final (kind, tabsRouter) in [
    ('AutoTabsRouter.tabBar', () => AutoTabsRouter.tabBar(routes: _kTabs, builder: (context, child, _) => child)),
    ('AutoTabsRouter.pageView', () => const AutoTabsRouter.pageView(routes: _kTabs)),
  ]) {
    testWidgets('Swiping $kind to a tab never opened shows its page', (tester) async {
      final router = _router(tabsRouter);
      await pumpRouterApp(tester, router);
      expect(find.text('Tab1Route'), findsOneWidget);

      final gesture = await tester.startGesture(tester.getCenter(find.text('Tab1Route')));
      await gesture.moveBy(const Offset(-200, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-300, 0));
      await tester.pump();
      expect(find.text('Tab2Route'), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(router.innerRouterOf<TabsRouter>('TabsRoute')!.activeIndex, 1);
      expect(find.text('Tab2Route'), findsOneWidget);

      // And on to the third, also never opened.
      await tester.fling(find.text('Tab2Route'), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Tab3Route'), findsOneWidget);
    });
  }
}

const _kTabs = [_Route('Tab1'), _Route('Tab2'), _Route('Tab3')];

RootStackRouter _router(Widget Function() tabsRouter) => .build(
  routes: [
    AutoRoute(
      path: '/',
      page: PageInfo('TabsRoute', builder: (_) => tabsRouter()),
      children: [
        for (final tab in ['Tab1', 'Tab2', 'Tab3'])
          AutoRoute(
            path: tab.toLowerCase(),
            page: EmptyShellRoute(tab),
            children: [
              AutoRoute(
                path: '',
                page: PageInfo(
                  '${tab}Route',
                  builder: (_) => Scaffold(body: Center(child: Text('${tab}Route'))),
                ),
              ),
            ],
          ),
      ],
    ),
  ],
);

class _Route extends PageRouteInfo<void> {
  const _Route(super.name);
}
