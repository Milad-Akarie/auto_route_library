import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

PageInfo _tab(String name) =>
    .new(name, builder: (_) => Center(child: Text(name)));

enum _Kind { pageView, tabBar }

RootStackRouter _router(Widget Function(List<PageRouteInfo> routes) tabs) {
  const routes = [
    PageRouteInfo('OneRoute'),
    PageRouteInfo('TwoRoute'),
    PageRouteInfo('ThreeRoute'),
  ];
  return RootStackRouter.build(
    routes: [
      AutoRoute(
        path: '/',
        page: PageInfo('HostRoute', builder: (_) => tabs(routes)),
        children: [
          AutoRoute(path: 'one', page: _tab('OneRoute')),
          AutoRoute(path: 'two', page: _tab('TwoRoute')),
          AutoRoute(path: 'three', page: _tab('ThreeRoute')),
        ],
      ),
    ],
  );
}

// https://github.com/Milad-Akarie/auto_route_library/issues/1149 and #1150
// Steps: build AutoTabsRouter.pageView or .tabBar with
// scrollDirection, physics or a zero duration, then drag or go to another tab.
// Reported: the options were missing, or animatePageTransition did nothing.
// Should: scrollDirection and physics reach the view, and a zero duration
// shows the new tab at once, without an animation.
void main() {
  testWidgets(
    'pageView with a vertical scrollDirection changes tab by a vertical drag '
    'only',
    (tester) async {
      final router = _router(
        (routes) =>
            AutoTabsRouter.pageView(routes: routes, scrollDirection: .vertical),
      );
      await pumpRouterApp(tester, router);
      final tabs = router.innerRouterOf<TabsRouter>('HostRoute')!;

      await tester.drag(find.byType(AutoPageView), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(tabs.activeIndex, 0);

      await tester.drag(find.byType(AutoPageView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(tabs.activeIndex, 1);
    },
  );

  for (final kind in _Kind.values) {
    testWidgets(
      '${kind.name} with NeverScrollableScrollPhysics ignores a drag',
      (tester) async {
        final router = _router(
          (routes) => switch (kind) {
            .pageView => AutoTabsRouter.pageView(
              routes: routes,
              physics: const NeverScrollableScrollPhysics(),
            ),
            .tabBar => AutoTabsRouter.tabBar(
              routes: routes,
              physics: const NeverScrollableScrollPhysics(),
            ),
          },
        );
        await pumpRouterApp(tester, router);
        final tabs = router.innerRouterOf<TabsRouter>('HostRoute')!;

        await tester.drag(find.text('OneRoute'), const Offset(-300, 0));
        await tester.pumpAndSettle();
        expect(tabs.activeIndex, 0);
      },
    );

    testWidgets(
      '${kind.name} with its animation off shows the new tab after one frame',
      (tester) async {
        final router = _router(
          (routes) => switch (kind) {
            .pageView => AutoTabsRouter.pageView(
              routes: routes,
              animatePageTransition: false,
            ),
            .tabBar => AutoTabsRouter.tabBar(routes: routes, duration: .zero),
          },
        );
        await pumpRouterApp(tester, router);
        final tabs = router.innerRouterOf<TabsRouter>('HostRoute')!
          ..setActiveIndex(2);
        await tester.pump();
        await tester.pump();
        expect(tabs.activeIndex, 2);
        final viewport = tester.getRect(find.byType(Scrollable).first);
        expect(
          tester.getRect(find.text('ThreeRoute')).center.dx,
          closeTo(viewport.center.dx, 1),
        );
        expect(find.text('OneRoute'), findsNothing);
      },
    );
  }
}
