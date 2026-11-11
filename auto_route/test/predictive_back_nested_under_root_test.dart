import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'back_test_utils.dart';
import 'router_test_utils.dart';

// Guard for flutter/flutter#152323 (interleaved nested Navigators and
// predictive back).
// Setup, as in the report: Android with predictive back, a host page whose
// nested router starts on a first page, and a root page pushed on top of the
// host.
// Steps: push a second page into the nested router, push the root page, then
// make the predictive back gesture.
// Happened (in Flutter): the nested router's second page took the gesture,
// so the user saw nothing happen and the next gesture popped the root page.
// Should: the gesture pops the root page, the one on screen, and the nested
// router keeps its two pages.
// Already works on dev: a page's popGestureEnabled
// (lib/src/router/auto_route_page.dart) is off while the top-most router can
// still pop.
void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      defaultRouteType: const RouteType.material(
        enablePredictiveBackGesture: true,
      ),
      routes: [
        AutoRoute(
          page: PageInfo('HostRoute', builder: (_) => const AutoRouter()),
          path: '/',
          children: [
            AutoRoute(page: _page('FirstRoute'), path: '', initial: true),
            AutoRoute(page: _page('SecondRoute'), path: 'second'),
          ],
        ),
        AutoRoute(page: _page('TopRoute'), path: '/top'),
      ],
    );
  });

  testWidgets(
    'the predictive back gesture pops the root page above a nested stack',
    (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      unawaited(
        router
            .innerRouterOf<StackRouter>('HostRoute')!
            .push(const _Route('SecondRoute')),
      );
      await tester.pumpAndSettle();
      unawaited(router.push(const _Route('TopRoute')));
      await tester.pumpAndSettle();
      final host = router.innerRouterOf<StackRouter>('HostRoute')!;
      expect(host.stack.map((page) => page.routeData.name), [
        'FirstRoute',
        'SecondRoute',
      ]);

      await predictiveBack(tester);

      expect(router.stack.map((page) => page.routeData.name), ['HostRoute']);
      expect(host.stack.map((page) => page.routeData.name), [
        'FirstRoute',
        'SecondRoute',
      ], reason: 'after predictiveBack(tester)');
      expect(find.text('SecondRoute'), findsOneWidget);
    },
  );
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));

class _Route extends PageRouteInfo<void> {
  const new(super.name);
}
