import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

PageInfo _tab(String name) => .new(name, builder: (_) => Center(child: Text(name)));

// https://github.com/Milad-Akarie/auto_route_library/issues/1197
// Steps: AutoTabsRouter.tabBar and .pageView take their routes from a
// getter that returns three to six tabs; the window is resized (the browser's
// full screen button) and the number of tabs changes.
// Reported: a red error screen (viewportDimension null in didUpdateWidget).
// Should: no error, and the tabs follow the list.
void main() {
  for (final tabBar in [true, false]) {
    testWidgets('${tabBar ? 'tabBar' : 'pageView'}: changing the tab count while the window resizes throws nothing', (
      tester,
    ) async {
      final count = ValueNotifier(3);
      addTearDown(count.dispose);
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: PageInfo(
              'HostRoute',
              builder: (_) => ValueListenableBuilder<int>(
                valueListenable: count,
                builder: (_, n, _) {
                  final routes = [for (var i = 0; i < n; i++) PageRouteInfo('Tab${i}Route')];
                  return tabBar ? AutoTabsRouter.tabBar(routes: routes) : AutoTabsRouter.pageView(routes: routes);
                },
              ),
            ),
            children: [for (var i = 0; i < 6; i++) AutoRoute(path: 'tab$i', page: _tab('Tab${i}Route'))],
          ),
        ],
      );
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 600);
      await pumpRouterApp(tester, router);
      final tabs = router.innerRouterOf<TabsRouter>('HostRoute')!;
      expect(tabs.pageCount, 3);

      tabs.setActiveIndex(2);
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(1200, 800);
      count.value = 6;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tabs.pageCount, 6);
      expect(tabs.activeIndex, 2);

      tester.view.physicalSize = const Size(500, 800);
      count.value = 4;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tabs.pageCount, 4);
      expect(find.text('Tab2Route'), findsOneWidget);
    });
  }
}
