import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/1320
// Setup: AutoTabsRouter.pageView(animatePageTransition: false) with 3 tabs.
// Steps: tabsRouter.setActiveIndex(1), then pump a single frame.
// Should: the page view is already on page 1, with no slide. With
// animatePageTransition: true (the control) it is still sliding after that frame.
void main() {
  for (final animate in [false, true]) {
    testWidgets('Switching a tab with animatePageTransition: $animate', (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: PageInfo('HostRoute', builder: (_) => AutoTabsRouter.pageView(animatePageTransition: animate)),
            children: [
              for (final name in ['A', 'B', 'C'])
                AutoRoute(
                  path: name.toLowerCase(),
                  page: PageInfo('${name}Route', builder: (_) => Text(name)),
                  initial: name == 'A',
                ),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      final controller = tester.widget<AutoPageView>(find.byType(AutoPageView)).controller;
      expect(controller.page, 0);

      router.innerRouterOf<TabsRouter>('HostRoute')!.setActiveIndex(1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      if (animate) {
        expect(controller.page, allOf(greaterThan(0), lessThan(1)));
      } else {
        expect(controller.page, 1);
      }
      await tester.pumpAndSettle();
      expect(controller.page, 1);
    });
  }
}
