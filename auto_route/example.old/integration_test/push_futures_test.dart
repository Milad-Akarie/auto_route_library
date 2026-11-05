import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/pages.dart';

// Push futures complete when their routes are removed.
// https://github.com/Milad-Akarie/auto_route_library/issues/2307
// Headless tests: auto_route/test/simple_router/router_widget_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RootStackRouter router;
  setUp(() => router = buildSimpleRouter());

  // Steps: push SecondRoute and ThirdRoute, each awaiting its result,
  // then remove both with removeWhere.
  // Should: both push futures complete with null and FirstRoute shows.
  testWidgets('Removing multiple routes completes each push future (#2307)', (tester) async {
    await pumpRouterApp(tester, router);
    final results = <String, String?>{};
    unawaited(router.push<String>(const SecondRoute()).then((result) => results[SecondRoute.name] = result));
    await tester.pumpAndSettle();
    unawaited(router.push<String>(const ThirdRoute()).then((result) => results[ThirdRoute.name] = result));
    await tester.pumpAndSettle();

    router.removeWhere((route) => route.name != FirstRoute.name);
    await tester.pumpAndSettle();

    expectCurrentPage(router, FirstRoute.name);
    expect(results, {SecondRoute.name: null, ThirdRoute.name: null});
  });

  // Steps: push SecondRoute and ThirdRoute, then remove every route.
  // Should: the stack is empty and both push futures complete with null.
  testWidgets('Clearing the stack completes each push future (#2307)', (tester) async {
    await pumpRouterApp(tester, router);
    final results = <String, String?>{};
    unawaited(router.push<String>(const SecondRoute()).then((result) => results[SecondRoute.name] = result));
    await tester.pumpAndSettle();
    unawaited(router.push<String>(const ThirdRoute()).then((result) => results[ThirdRoute.name] = result));
    await tester.pumpAndSettle();

    router.removeWhere((route) => true);
    await tester.pumpAndSettle();

    expect(router.stack, isEmpty);
    expect(results, {SecondRoute.name: null, ThirdRoute.name: null});
  });

  // Steps: push SecondRoute and ThirdRoute, remove SecondRoute (not on
  // top), then pop ThirdRoute with 'done'.
  // Should: only SecondRoute's future completes at first; ThirdRoute's
  // completes with 'done' when it is popped.
  testWidgets('Removing a route below the top completes only its push future (#2307)', (tester) async {
    await pumpRouterApp(tester, router);
    final results = <String, String?>{};
    unawaited(router.push<String>(const SecondRoute()).then((result) => results[SecondRoute.name] = result));
    await tester.pumpAndSettle();
    unawaited(router.push<String>(const ThirdRoute()).then((result) => results[ThirdRoute.name] = result));
    await tester.pumpAndSettle();

    router.removeRoute(router.stackData.firstWhere((route) => route.name == SecondRoute.name));
    await tester.pumpAndSettle();

    expectCurrentPage(router, ThirdRoute.name);
    expect(results, {SecondRoute.name: null});

    router.pop<String>('done');
    await tester.pumpAndSettle();
    expectCurrentPage(router, FirstRoute.name);
    expect(results, {SecondRoute.name: null, ThirdRoute.name: 'done'});
  });

  // Steps: FourthRoute's guard pushes SecondRoute (a login flow) and
  // awaits it; push FourthRoute, push ThirdRoute on the flow, then remove the
  // flow's routes.
  // Should: the guard resumes and FourthRoute shows.
  testWidgets('Removing a login flow resumes a guard awaiting its push future (#2307)', (tester) async {
    var guardResumed = false;
    final guardedRouter = RootStackRouter.build(
      routes: [
        AutoRoute(page: FirstRoute.page, initial: true),
        AutoRoute(page: SecondRoute.page),
        AutoRoute(page: ThirdRoute.page),
        AutoRoute.guarded(
          page: FourthRoute.page,
          onNavigation: (resolver, router) async {
            await router.push(const SecondRoute());
            guardResumed = true;
            resolver.next();
          },
        ),
      ],
    );
    await pumpRouterApp(tester, guardedRouter);
    unawaited(guardedRouter.push(const FourthRoute()));
    await tester.pumpAndSettle();
    expectCurrentPage(guardedRouter, SecondRoute.name);
    unawaited(guardedRouter.push(const ThirdRoute()));
    await tester.pumpAndSettle();

    guardedRouter.removeWhere((route) => route.name == SecondRoute.name || route.name == ThirdRoute.name);
    await tester.pumpAndSettle();

    expect(guardResumed, isTrue);
    expectCurrentPage(guardedRouter, FourthRoute.name);
  });
}
