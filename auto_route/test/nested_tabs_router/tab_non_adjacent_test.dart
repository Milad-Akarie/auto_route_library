import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../main_router.dart';
import '../router_test_utils.dart';
import 'router.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/1063 and #1062
// Steps: in a tab view of three tabs showing the first, go to the third tab
// with setActiveIndex(2).
// Happened: the view visibly passed the second tab, or didn't slide at all.
// Should: the view slides from the first tab to the third, and the second
// tab is never on screen on the way.
void main() {
  for (final tabsType in ['TabBar', 'PageView']) {
    testWidgets(
      '$tabsType: going to a non-adjacent tab never shows the tab between',
      (tester) async {
        final router = NestedTabsRouter();
        await pumpRouterConfigApp(
          tester,
          router.config(
            deepLinkBuilder: (_) =>
                DeepLink.single(TabsHostRoute(tabsType: tabsType)),
          ),
        );
        final tabsRouter = router.innerRouterOf<TabsRouter>(
          TabsHostRoute.name,
        )!;
        final viewport = tester.getRect(find.byType(Scrollable).first);

        bool isOnScreen(String text) {
          final finder = find.text(text, skipOffstage: false);
          return finder.evaluate().isNotEmpty &&
              tester.getRect(finder).overlaps(viewport);
        }

        tabsRouter.setActiveIndex(2);
        var didSeeFirst = false;
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 20));
          didSeeFirst |= isOnScreen(Tab1Route.name);
          expect(
            isOnScreen(Tab2Nested1Route.name),
            isFalse,
            reason: 'the tab between is on screen at frame $i',
          );
        }
        await tester.pumpAndSettle();
        expect(
          didSeeFirst,
          isTrue,
          reason: 'the first tab should slide out, not vanish',
        );
        expectTopPage(router, Tab3Nested1Route.name);
      },
    );
  }
}
