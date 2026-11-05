import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/flutter/flutter/issues/129639
// Setup: bottom tabs; the second bottom tab holds a TabBar with a swipeable
// tab view of two tabs, never tapped.
// Steps: open the second bottom tab, then swipe its tab view to the next tab
// without touching the TabBar.
// Should: the swipe makes the next tab active, shows its page, and the url
// follows.
void main() {
  testWidgets('Swiping a tab view nested in a bottom tab switches the tab and the url', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('HomeRoute', builder: (_) => const AutoTabsRouter(routes: [_Route('A'), _Route('B')])),
          children: [
            AutoRoute(path: 'a', page: _page('A')),
            AutoRoute(
              path: 'b',
              page: PageInfo(
                'B',
                builder: (_) => AutoTabsRouter.tabBar(
                  routes: const [_Route('B1'), _Route('B2')],
                  builder: (context, child, controller) => Scaffold(
                    appBar: AppBar(
                      bottom: TabBar(
                        controller: controller,
                        tabs: const [
                          Tab(text: 'First'),
                          Tab(text: 'Second'),
                        ],
                      ),
                    ),
                    body: child,
                  ),
                ),
              ),
              children: [
                AutoRoute(path: 'b1', page: _page('B1')),
                AutoRoute(path: 'b2', page: _page('B2')),
              ],
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    router.innerRouterOf<TabsRouter>('HomeRoute')!.setActiveIndex(1);
    await tester.pumpAndSettle();
    expect(find.text('B1 page'), findsOneWidget);
    expect(router.urlState.url, '/b/b1');

    await tester.fling(find.text('B1 page'), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final inner = router.innerRouterOf<TabsRouter>('HomeRoute')!.innerRouterOf<TabsRouter>('B')!;
    expect(inner.activeIndex, 1);
    expect(find.text('B2 page'), findsOneWidget);
    expect(router.urlState.url, '/b/b2');
  });
}

PageInfo _page(String name) => .new(name, builder: (_) => Center(child: Text('$name page')));

class _Route extends PageRouteInfo<void> {
  const new(super.name);
}
