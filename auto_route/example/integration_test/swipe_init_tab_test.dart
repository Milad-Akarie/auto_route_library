import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// Swiping a page view or tab bar to a tab never opened fires didInitTabRoute.
// Found while settling the observer issues; no upstream report.
// Headless test: auto_route/test/nested_tabs_router/swipe_init_tab_observer_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const tabs = [NamedRoute('Tab1Route'), NamedRoute('Tab2Route'), NamedRoute('Tab3Route')];

  RootStackRouter buildRouter(Widget Function() tabsRouter) => RootStackRouter.build(
    routes: [
      AutoRoute(
        path: '/',
        page: PageInfo('TabsRoute', builder: (_) => tabsRouter()),
        children: [
          for (final name in ['Tab1Route', 'Tab2Route', 'Tab3Route'])
            AutoRoute(
              path: name.toLowerCase(),
              page: PageInfo(name, builder: (_) => Center(child: Text(name))),
            ),
        ],
      ),
    ],
  );

  // Steps: tabs with an observer. Swipe forward to the second tab, never
  // opened, then back to the first, then forward to the second again.
  // Should: the first swipe to Tab2Route fires didInitTabRoute; the next two
  // fire didChangeTabRoute.
  Future<void> expectSwipesInitNewTabs(WidgetTester tester, RootStackRouter router) async {
    final tabEvents = <String>[];
    await pumpRouterApp(tester, router, navigatorObservers: () => [_TabEventObserver(tabEvents)]);
    final tabsRouter = router.innerRouterOf<TabsRouter>('TabsRoute')!;
    expect(tabEvents, ['init Tab1Route from null']);
    // Most of the screen's width, so each swipe turns a page on a wide screen too.
    final swipe = Offset(tester.view.physicalSize.width / tester.view.devicePixelRatio * 0.8, 0);

    await tester.fling(find.text('Tab1Route'), -swipe, 1000);
    await tester.pumpAndSettle();
    expect(tabsRouter.activeIndex, 1);
    expect(tabEvents.last, 'init Tab2Route from Tab1Route');

    await tester.fling(find.text('Tab2Route'), swipe, 1000);
    await tester.pumpAndSettle();
    expect(tabsRouter.activeIndex, 0);
    expect(tabEvents.last, 'change Tab1Route from Tab2Route');

    await tester.fling(find.text('Tab1Route'), -swipe, 1000);
    await tester.pumpAndSettle();
    expect(tabsRouter.activeIndex, 1);
    expect(tabEvents.last, 'change Tab2Route from Tab1Route');
  }

  testWidgets('swiping a page view to a tab never opened fires didInitTabRoute', (tester) async {
    await expectSwipesInitNewTabs(tester, buildRouter(() => const AutoTabsRouter.pageView(routes: tabs)));
  });

  testWidgets('swiping a tab bar to a tab never opened fires didInitTabRoute', (tester) async {
    await expectSwipesInitNewTabs(
      tester,
      buildRouter(() => AutoTabsRouter.tabBar(routes: tabs, builder: (context, child, controller) => child)),
    );
  });
}

/// Records each tab event as `'<init|change> <tab> from <previous tab>'`.
class _TabEventObserver extends AutoRouterObserver {
  _TabEventObserver(this.tabEvents);

  final List<String> tabEvents;

  @override
  void didInitTabRoute(TabPageRoute route, TabPageRoute? previousRoute) {
    tabEvents.add('init ${route.name} from ${previousRoute?.name}');
  }

  @override
  void didChangeTabRoute(TabPageRoute route, TabPageRoute previousRoute) {
    tabEvents.add('change ${route.name} from ${previousRoute.name}');
  }
}
