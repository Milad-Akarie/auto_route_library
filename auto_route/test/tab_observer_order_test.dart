import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/2132
// Setup, as the reporter has it. The initial route 'HostRoute' shows an
// AutoTabsRouter over 'HostFirstRoute' and 'SecondRoute'. 'SecondRoute' is
// the initial child. 'HostFirstRoute' shows an AutoTabsRouter over
// 'FirstARoute' and 'FirstBRoute'. An observer records didInitTabRoute and
// didChangeTabRoute.
// The steps: the app opens on Second. Then the outer tabs switch to
// HostFirst, which has not been shown yet.
// Reported (7.8.4 to 9.3.0): the inner router's didInitTabRoute came before
// the outer router's didChangeTabRoute; older versions had the reverse.
// Nobody on the thread said which order is right. Pinned, as the code does it
// today: a tab shown for the first time reports didInitTabRoute, not
// didChangeTabRoute, so the outer router's init of HostFirst comes first and
// the inner router's init of FirstA after it, as the inner tabs only exist
// once the outer tab is shown. A tab shown again reports didChangeTabRoute,
// and the inner router stays silent. The test fails if the inner init comes
// before the outer one, or the outer tab reports in another way.
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
            AutoRoute(
              page: _page('SecondRoute'),
              path: 'second',
              initial: true,
            ),
          ],
        ),
      ],
    );
  });

  testWidgets('An outer tab reports before the tabs inside it', (tester) async {
    await pumpRouterApp(tester, router, observers: () => [_Recorder(events)]);
    final outer = router.innerRouterOf<TabsRouter>('HostRoute')!;
    expect(outer.activeIndex, 1, reason: 'the app starts on Second');
    expect(events, ['init SecondRoute']);

    events.clear();
    outer.setActiveIndex(0);
    await tester.pumpAndSettle();
    expect(events, ['init HostFirstRoute', 'init FirstARoute']);

    events.clear();
    outer.setActiveIndex(1);
    await tester.pumpAndSettle();
    outer.setActiveIndex(0);
    await tester.pumpAndSettle();
    expect(events, ['change SecondRoute', 'change HostFirstRoute']);
  });
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
