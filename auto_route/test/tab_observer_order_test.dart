import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/2132
// Setup: the initial route 'HostRoute' shows an AutoTabsRouter over
// 'HostFirstRoute' and 'SecondRoute'; 'HostFirstRoute' shows an
// AutoTabsRouter over 'FirstARoute' and 'FirstBRoute'. An observer records
// didInitTabRoute and didChangeTabRoute.
// Steps: open the app, switch the outer tabs to Second, then back to
// HostFirst.
// Reported (7.8.4 to 9.3.0): the inner router's didInitTabRoute came before
// the outer router's didChangeTabRoute; older versions had the reverse.
// Should (assumed, as nobody answered which is right): an outer tab reports
// its change before the tabs inside it report their init, because the outer
// tab is what opens them. The test records the order and asserts that one.
void main() {
  late List<String> events;
  late RootStackRouter router;

  setUp(() {
    events = [];
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: PageInfo(
            'HostRoute',
            builder: (_) => AutoTabsRouter(
              routes: const [
                PageRouteInfo('HostFirstRoute'),
                PageRouteInfo('SecondRoute'),
              ],
              builder: (context, child) => child,
            ),
          ),
          path: '/',
          initial: true,
          children: [
            AutoRoute(
              page: PageInfo(
                'HostFirstRoute',
                builder: (_) => AutoTabsRouter(
                  routes: const [
                    PageRouteInfo('FirstARoute'),
                    PageRouteInfo('FirstBRoute'),
                  ],
                  builder: (context, child) => child,
                ),
              ),
              path: 'first',
              children: [
                AutoRoute(page: _page('FirstARoute'), path: 'a'),
                AutoRoute(page: _page('FirstBRoute'), path: 'b'),
              ],
            ),
            AutoRoute(page: _page('SecondRoute'), path: 'second'),
          ],
        ),
      ],
    );
  });

  testWidgets(
    'An outer tab reports its change before the tabs inside it report init',
    (tester) async {
      await pumpRouterApp(tester, router, observers: () => [_Recorder(events)]);
      final outer = router.innerRouterOf<TabsRouter>('HostRoute')!;
      expect(
        events,
        containsAllInOrder(['init HostFirstRoute', 'init FirstARoute']),
      );

      events.clear();
      outer.setActiveIndex(1);
      await tester.pumpAndSettle();
      expect(events, ['init SecondRoute'], reason: 'first visit of a tab');

      events.clear();
      outer.setActiveIndex(0);
      await tester.pumpAndSettle();
      expect(events.take(1), ['change HostFirstRoute'], reason: '$events');
    },
  );
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));

class _Recorder extends AutoRouterObserver {
  new(this.events);

  final List<String> events;

  @override
  void didInitTabRoute(TabPageRoute route, TabPageRoute? previousRoute) =>
      events.add('init ${route.name}');

  @override
  void didChangeTabRoute(TabPageRoute route, TabPageRoute previousRoute) =>
      events.add('change ${route.name}');
}
