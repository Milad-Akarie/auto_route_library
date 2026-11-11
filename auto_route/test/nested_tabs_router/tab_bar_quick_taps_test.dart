import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/1061
  // Reported: with AutoTabsRouter.tabBar and a BottomNavigationBar, taps on
  // the bar during the tab animation were ignored until it ended.
  // Steps: tap the second item, 50ms later the fourth, 50ms later the
  // third; then the first and, 30ms later, the second.
  // Should: each time the last tap wins: its tab is active and on screen.
  testWidgets(
    'Taps on a bottom bar while the tab bar animates switch to the last '
    'tapped tab',
    (tester) async {
      const names = ['Tab1Route', 'Tab2Route', 'Tab3Route', 'Tab4Route'];
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HostRoute',
            path: '/',
            builder: (_, _) => AutoTabsRouter.tabBar(
              routes: [for (final name in names) NamedRoute(name)],
              builder: (context, child, _) => Scaffold(
                body: child,
                bottomNavigationBar: BottomNavigationBar(
                  type: .fixed,
                  currentIndex: context.tabsRouter.activeIndex,
                  onTap: context.tabsRouter.setActiveIndex,
                  items: [
                    for (var i = 1; i <= names.length; i++)
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.circle),
                        label: 'item $i',
                      ),
                  ],
                ),
              ),
            ),
            children: [
              for (final name in names)
                NamedRouteDef(
                  name: name,
                  path: name.toLowerCase(),
                  builder: (_, _) => Center(child: Text(name)),
                ),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      final tabs = router.innerRouterOf<TabsRouter>('HostRoute')!;

      await tester.tap(find.text('item 2'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('item 4'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('item 3'));
      await tester.pumpAndSettle();
      expect(tabs.activeIndex, 2);
      expect(find.text('Tab3Route'), findsOneWidget);
      expect(find.text('Tab4Route'), findsNothing);

      await tester.tap(find.text('item 1'));
      await tester.pump(const Duration(milliseconds: 30));
      await tester.tap(find.text('item 2'));
      await tester.pumpAndSettle();
      expect(tabs.activeIndex, 1);
      expect(find.text('Tab2Route'), findsOneWidget);
      expect(find.text('Tab1Route'), findsNothing);
    },
  );
}
