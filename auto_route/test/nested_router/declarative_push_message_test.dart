import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/2127
// Steps: a page builds AutoRouter.declarative; the app pushes one of that
// router's routes, as `context.router.push(BRoute())`.
// Reported: the assert "Pages stack can be managed by either the Widget
// (AutoRouter.declarative) or Router" names neither the router nor the fix.
// Should: the message names the router and says how to change its pages.
void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'HostRoute',
            builder: (_) => AutoRouter.declarative(routes: (_) => [const PageRouteInfo('ARoute')]),
          ),
          children: [
            AutoRoute(
              path: '',
              page: PageInfo('ARoute', builder: (_) => const Text('A')),
            ),
            AutoRoute(
              path: 'b',
              page: PageInfo('BRoute', builder: (_) => const Text('B')),
            ),
          ],
        ),
      ],
    );
  });

  Matcher namesRouterAndFix() => isA<AssertionError>().having(
    (e) => e.message,
    'message',
    allOf(
      contains('router of HostRoute'),
      contains('AutoRouter.declarative'),
      contains('routes callback'),
      contains('AutoRouter()'),
    ),
  );

  testWidgets('pushing a route of a declarative router names the router and the fix', (tester) async {
    await pumpRouterApp(tester, router);
    await expectLater(router.push(const PageRouteInfo('BRoute')), throwsA(namesRouterAndFix()));
  });

  testWidgets('pushing several routes of a declarative router names the router and the fix', (tester) async {
    await pumpRouterApp(tester, router);
    final inner = router.innerRouterOf<StackRouter>('HostRoute')!;
    await expectLater(inner.pushAll([const PageRouteInfo('BRoute')]), throwsA(namesRouterAndFix()));
  });
}
