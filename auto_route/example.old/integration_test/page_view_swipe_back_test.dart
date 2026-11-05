import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// Swiping AutoTabsRouter.pageView back to a lower tab fires didChangeTabRoute.
// Guards https://github.com/Milad-Akarie/auto_route_library/issues/2044
// Headless test: auto_route/test/nested_tabs_router/page_view_observer_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: AutoTabsRouter.pageView with three tabs and an observer. Swipe to
  // the second tab, then swipe back to the first one.
  // Should: the swipe back fires didChangeTabRoute for Tab1Route, from Tab2Route.
  testWidgets('swiping a page view back to a lower tab fires didChangeTabRoute', (tester) async {
    final tabChanges = <String>[];
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'TabsRoute',
            builder: (_) => const AutoTabsRouter.pageView(
              routes: [NamedRoute('Tab1Route'), NamedRoute('Tab2Route'), NamedRoute('Tab3Route')],
            ),
          ),
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
    await pumpRouterApp(tester, router, navigatorObservers: () => [_TabChangeObserver(tabChanges)]);
    final tabsRouter = router.innerRouterOf<TabsRouter>('TabsRoute')!;
    // Each swipe covers three quarters of a page, so it changes the page even
    // when the swipe's speed reads zero, as after a slow frame on CI.
    final swipe = tester.getSize(find.ancestor(of: find.text('Tab1Route'), matching: find.byType(Center))).width * 0.75;

    await tester.drag(find.text('Tab1Route'), Offset(-swipe, 0));
    await tester.pumpAndSettle();
    expect(tabsRouter.activeIndex, 1);

    tabChanges.clear();
    await tester.drag(find.text('Tab2Route'), Offset(swipe, 0));
    await tester.pumpAndSettle();
    expect(tabsRouter.activeIndex, 0);
    expect(tabChanges, ['Tab1Route from Tab2Route']);
  });
}

/// Records each didChangeTabRoute as `'<tab> from <previous tab>'`.
class _TabChangeObserver extends AutoRouterObserver {
  _TabChangeObserver(this.tabChanges);

  final List<String> tabChanges;

  @override
  void didChangeTabRoute(TabPageRoute route, TabPageRoute previousRoute) {
    tabChanges.add('${route.name} from ${previousRoute.name}');
  }
}
