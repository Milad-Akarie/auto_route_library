import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';
import 'disposal_tracker.dart';

RootStackRouter _buildRouter(Widget Function() tabsRouter) => .build(
  routes: [
    AutoRoute(
      path: '/',
      page: PageInfo('HomeRoute', builder: (_) => const Text('HomeRoute')),
    ),
    AutoRoute(
      path: '/tabs',
      page: PageInfo('TabsHostRoute', builder: (_) => tabsRouter()),
      children: [
        AutoRoute(
          path: 'tab1',
          page: PageInfo('Tab1Route', builder: (_) => const Text('Tab1Route')),
        ),
        AutoRoute(
          path: 'tab2',
          page: PageInfo('Tab2Route', builder: (_) => const Text('Tab2Route')),
        ),
      ],
    ),
  ],
);

const List<PageRouteInfo> _kTabs = [
  NamedRoute('Tab1Route'),
  NamedRoute('Tab2Route'),
];

void main() {
  // Steps: push TabsHostRoute, whose page holds an AutoTabsRouter.tabBar
  // showing an AutoTabView, switch tabs, then pop the host.
  // Happened: the PageController the AutoTabView creates stayed
  // undisposed, one more on each visit.
  // Should: popping the host disposes it.
  testWidgets('Popping an AutoTabView disposes its PageController', (
    tester,
  ) async {
    final router = _buildRouter(
      () => AutoTabsRouter.tabBar(
        routes: _kTabs,
        builder: (context, child, controller) => Column(
          children: [
            TabBar(
              controller: controller,
              tabs: const [
                Tab(text: 'One'),
                Tab(text: 'Two'),
              ],
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
    await pumpRouterApp(tester, router);
    final pageControllers = DisposalTracker<PageController>();
    unawaited(router.pushPath('/tabs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Two'));
    await tester.pumpAndSettle();
    expect(find.text('Tab2Route'), findsOneWidget);
    expect(pageControllers.created, 1);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('HomeRoute'), findsOneWidget);
    expect(pageControllers.undisposed, 0);
  });

  // Steps: push TabsHostRoute, whose page holds a pageView tabs router.
  // Swipe to the second tab, then pop the host.
  // Happened: the PageController the tabs router creates stayed undisposed, one
  // more on each visit. Should: popping the host disposes it.
  testWidgets(
    'Popping an AutoTabsRouter.pageView disposes its PageController',
    (tester) async {
      final router = _buildRouter(
        () => const AutoTabsRouter.pageView(routes: _kTabs),
      );
      await pumpRouterApp(tester, router);
      final pageControllers = DisposalTracker<PageController>();
      unawaited(router.pushPath('/tabs'));
      await tester.pumpAndSettle();
      await tester.fling(find.text('Tab1Route'), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Tab2Route'), findsOneWidget);
      expect(pageControllers.created, 1);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('HomeRoute'), findsOneWidget);
      expect(pageControllers.undisposed, 0);
    },
  );
}
