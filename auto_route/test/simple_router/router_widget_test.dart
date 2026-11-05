import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

import '../main_router.dart';
import '../router_test_utils.dart';
import 'router.dart';

void main() {
  late SimpleRouter router;
  setUp(() {
    router = SimpleRouter();
  });

  testWidgets('Initial route should be ${FirstRoute.name}', (tester) async {
    await pumpRouterApp(tester, router);
    expect(find.text(FirstRoute.name), findsOneWidget);
  });

  testWidgets('Pushing ${SecondRoute.name} should show [SecondPage]', (
    tester,
  ) async {
    await pumpRouterApp(tester, router);
    unawaited(router.push(const SecondRoute()));
    await tester.pumpAndSettle();
    expect(find.text(SecondRoute.name), findsOneWidget);
    expect(router.urlState.url, '/second-route');
  });

  testWidgets('Navigating to ${SecondRoute.name} should show [SecondPage]', (
    tester,
  ) async {
    await pumpRouterApp(tester, router);
    unawaited(router.navigate(const SecondRoute()));
    await tester.pumpAndSettle();
    expectCurrentPage(router, SecondRoute.name);
    expect(router.urlState.url, '/second-route');
  });

  testWidgets(
    'Pushing ${SecondRoute.name} then popping should show [FirstPage]',
    (tester) async {
      await pumpRouterApp(tester, router);
      unawaited(router.push(const SecondRoute()));
      await tester.pumpAndSettle();
      unawaited(router.maybePop());
      await tester.pumpAndSettle();
      expectCurrentPage(router, FirstRoute.name);
      expect(router.urlState.url, '/');
    },
  );

  testWidgets('Pushing ${SecondRoute.name} and ${ThirdRoute.name} should show '
      '[ThirdPage]', (tester) async {
    await pumpRouterApp(tester, router);
    unawaited(router.pushAll([const SecondRoute(), const ThirdRoute()]));
    await tester.pumpAndSettle();
    expectCurrentPage(router, ThirdRoute.name);
    expect(router.urlState.url, '/third-route');
  });

  testWidgets('Removing multiple routes should complete each push future', (
    tester,
  ) async {
    await pumpRouterApp(tester, router);
    final results = <String, String?>{};
    unawaited(
      router
          .push<String>(const SecondRoute())
          .then((result) => results[SecondRoute.name] = result),
    );
    await tester.pumpAndSettle();
    unawaited(
      router
          .push<String>(const ThirdRoute())
          .then((result) => results[ThirdRoute.name] = result),
    );
    await tester.pumpAndSettle();

    router.removeWhere((route) => route.name != FirstRoute.name);
    await tester.pumpAndSettle();

    expectCurrentPage(router, FirstRoute.name);
    expect(results, {SecondRoute.name: null, ThirdRoute.name: null});
  });

  testWidgets('Clearing the stack should complete each push future', (
    tester,
  ) async {
    await pumpRouterApp(tester, router);
    final results = <String, String?>{};
    unawaited(
      router
          .push<String>(const SecondRoute())
          .then((result) => results[SecondRoute.name] = result),
    );
    await tester.pumpAndSettle();
    unawaited(
      router
          .push<String>(const ThirdRoute())
          .then((result) => results[ThirdRoute.name] = result),
    );
    await tester.pumpAndSettle();

    router.removeWhere((route) => true);
    await tester.pumpAndSettle();

    expect(router.stack, isEmpty);
    expect(results, {SecondRoute.name: null, ThirdRoute.name: null});
  });

  testWidgets('Removing a non-top route should complete only its push future', (
    tester,
  ) async {
    await pumpRouterApp(tester, router);
    final results = <String, String?>{};
    unawaited(
      router
          .push<String>(const SecondRoute())
          .then((result) => results[SecondRoute.name] = result),
    );
    await tester.pumpAndSettle();
    unawaited(
      router
          .push<String>(const ThirdRoute())
          .then((result) => results[ThirdRoute.name] = result),
    );
    await tester.pumpAndSettle();

    router.removeRoute(
      router.stackData
          .where((route) => route.name == SecondRoute.name)
          .firstOrNull!,
    );
    await tester.pumpAndSettle();

    expectCurrentPage(router, ThirdRoute.name);
    expect(results, {SecondRoute.name: null});

    router.pop('done');
    await tester.pumpAndSettle();
    expectCurrentPage(router, FirstRoute.name);
    expect(results, {SecondRoute.name: null, ThirdRoute.name: 'done'});
  });

  testWidgets(
    'Removing a login flow should resume a guard awaiting its push future',
    (tester) async {
      var didGuardResume = false;
      final guardedRouter = RootStackRouter.build(
        routes: [
          AutoRoute(page: FirstRoute.page, initial: true),
          AutoRoute(page: SecondRoute.page),
          AutoRoute(page: ThirdRoute.page),
          AutoRoute.guarded(
            page: FourthRoute.page,
            onNavigation: (resolver, routerBeingGuarded) async {
              await routerBeingGuarded.push(const SecondRoute());
              didGuardResume = true;
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

      guardedRouter.removeWhere(
        (route) =>
            route.name == SecondRoute.name || route.name == ThirdRoute.name,
      );
      await tester.pumpAndSettle();

      expect(didGuardResume, isTrue);
      expectCurrentPage(guardedRouter, FourthRoute.name);
    },
  );

  // Reproduction for https://github.com/Milad-Akarie/auto_route_library/issues/2251
  // Steps: page A pushes page B and awaits its result; page B is replaced with
  // page C; page C is popped, which returns to page A.
  // Happens: the future returned by A's push() never completes.
  // Should happen: it completes when C is popped, as it did in 10.0.1.
  testWidgets(
    'Popping a route that replaced the pushed route should complete the '
    'original push future',
    (tester) async {
      await pumpRouterApp(tester, router);
      var isCompleted = false;
      unawaited(
        router
            .push<String>(const SecondRoute())
            .then((_) => isCompleted = true),
      );
      await tester.pumpAndSettle();

      unawaited(router.replace(const ThirdRoute()));
      await tester.pumpAndSettle();
      expectCurrentPage(router, ThirdRoute.name);

      router.pop();
      await tester.pumpAndSettle();

      expectCurrentPage(router, FirstRoute.name);
      expect(isCompleted, isTrue);
    },
  );

  // Reproduces https://github.com/Milad-Akarie/auto_route_library/issues/2154
  // Steps: await router.navigate(SecondRoute()), then pop SecondPage with a
  // result. Happens: the navigate() future completes right away with null,
  // before the page is popped. Should: it completes only when the page is
  // popped, with the popped result, as push() does.
  testWidgets(
    'navigate() should complete with the result the opened page is popped with',
    (tester) async {
      await pumpRouterApp(tester, router);
      var isCompleted = false;
      Object? result;
      unawaited(
        router.navigate(const SecondRoute()).then((value) {
          isCompleted = true;
          result = value;
        }),
      );
      await tester.pumpAndSettle();
      expectCurrentPage(router, SecondRoute.name);
      expect(
        isCompleted,
        isFalse,
        reason: 'navigate() completed before the page was popped',
      );

      router.pop('done');
      await tester.pumpAndSettle();
      expect(isCompleted, isTrue);
      expect(result, 'done');
    },
  );
}
