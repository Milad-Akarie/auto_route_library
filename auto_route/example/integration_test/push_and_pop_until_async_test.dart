import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// pushAndPopUntil removes the routes below the new page only once its guards
// let it through, on the stack as it is then.
// https://github.com/Milad-Akarie/auto_route_library/issues/1797
// Headless test: auto_route/test/guards/push_and_pop_until_slow_guard_test.dart.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Completer<bool> decision;
  late RootStackRouter router;
  setUp(() {
    decision = Completer<bool>();
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('HomeRoute'), path: '/', initial: true),
        AutoRoute(page: _page('ARoute'), path: '/a'),
        AutoRoute(page: _page('BRoute'), path: '/b'),
        AutoRoute(
          page: _page('CRoute'),
          path: '/c',
          guards: [
            AutoRouteGuardCallback((resolver, _) async {
              if (await decision.future) {
                resolver.next();
              } else {
                resolver.reject();
              }
            }),
          ],
        ),
      ],
    );
  });

  List<String> names() => router.stack.map((page) => page.routeData.name).toList();

  // Opens HomeRoute, ARoute and BRoute, then calls pushAndPopUntil(CRoute)
  // keeping HomeRoute, keeps its future in [pushedC] and waits while CRoute's
  // guard decides.
  late Future<Object?> pushedC;
  Future<void> pushCWhileGuardDecides(WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    unawaited(router.push(const PageRouteInfo('ARoute')));
    await tester.pumpAndSettle();
    unawaited(router.push(const PageRouteInfo('BRoute')));
    await tester.pumpAndSettle();

    pushedC = router.pushAndPopUntil(
      const PageRouteInfo('CRoute'),
      predicate: (route) => route.settings.name == 'HomeRoute',
    );
    await tester.pumpAndSettle();
    expect(names(), ['HomeRoute', 'ARoute', 'BRoute']);
    expectCurrentPage(router, 'BRoute');
  }

  // Steps: open HomeRoute, ARoute and BRoute, call pushAndPopUntil(CRoute)
  // keeping HomeRoute while CRoute's guard decides, pop BRoute, then let the
  // guard accept.
  // Should: nothing moves while the guard decides; then HomeRoute and CRoute
  // are left, and back goes to HomeRoute.
  testWidgets('pushAndPopUntil waits for a slow guard, then removes the routes left', (tester) async {
    await pushCWhileGuardDecides(tester);
    unawaited(router.maybePop());
    await tester.pumpAndSettle();
    expect(names(), ['HomeRoute', 'ARoute']);

    decision.complete(true);
    await tester.pumpAndSettle();
    expect(names(), ['HomeRoute', 'CRoute']);
    expectCurrentPage(router, 'CRoute');

    unawaited(router.maybePop());
    await tester.pumpAndSettle();
    expectCurrentPage(router, 'HomeRoute');
  });

  // Steps: open HomeRoute, ARoute and BRoute, call pushAndPopUntil(CRoute)
  // keeping HomeRoute, then let CRoute's guard reject.
  // Should: the stack stays as it was and the push completes with null.
  testWidgets('pushAndPopUntil rejected by a slow guard leaves the stack as it was', (tester) async {
    await pushCWhileGuardDecides(tester);

    decision.complete(false);
    expect(await pushedC, isNull);
    await tester.pumpAndSettle();
    expect(names(), ['HomeRoute', 'ARoute', 'BRoute']);
    expectCurrentPage(router, 'BRoute');
  });
}

PageInfo _page(String name) => .new(
  name,
  builder: (_) => Scaffold(appBar: AppBar(), body: Text(name)),
);
