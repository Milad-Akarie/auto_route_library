import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../main_router.dart';
import '../router_test_utils.dart';

class BackGestureRouter extends MainRouter {
  @override
  final List<AutoRoute> routes = [
    AutoRoute(path: '/', page: FirstRoute.page),
    AutoRoute(
      path: '/second',
      page: SecondHostRoute.page,
      children: [
        AutoRoute(path: '', page: SecondNested1Route.page),
        AutoRoute(path: 'nested3', page: SecondNested3Route.page),
        AutoRoute(
          path: 'deep',
          page: Tab2Route.page,
          children: [
            AutoRoute(path: '', page: Tab2Nested1Route.page),
            AutoRoute(path: 'nested2', page: Tab2Nested2Route.page),
          ],
        ),
      ],
    ),
  ];
}

Future<void> pumpIosApp(WidgetTester tester, RootStackRouter router) {
  return tester
      .pumpWidget(
        MaterialApp.router(
          theme: ThemeData(platform: .iOS),
          routeInformationParser: router.defaultRouteParser(),
          routerDelegate: router.delegate(),
        ),
      )
      .then((_) => tester.pumpAndSettle());
}

Future<void> swipeBack(WidgetTester tester) {
  return tester.dragFrom(const Offset(2, 300), const Offset(500, 0)).then((_) => tester.pumpAndSettle());
}

Future<void> systemBack(WidgetTester tester) {
  return tester.binding.handlePopRoute().then((_) => tester.pumpAndSettle());
}

void main() {
  late BackGestureRouter router;
  setUp(() {
    router = BackGestureRouter();
  });

  // Regression guard for https://github.com/Milad-Akarie/auto_route_library/issues/1932
  // (upstream PR 1941 targeted it).
  // Steps: push SecondHostRoute (its nested router shows SecondNested1Route),
  // push SecondNested3Route into that nested router, then go back the way the
  // system does: Android back, or the iOS edge swipe.
  // Should happen: only SecondNested3Route is popped; SecondHostRoute stays
  // with SecondNested1Route on screen. A second back then pops SecondHostRoute.
  // Already works on master: the method PR 1941 changes, activeRouterCanPop,
  // has had no callers since 98c31c1; the back gesture asks
  // topMostRouter.canPop instead.
  group('with a sub-route pushed in a nested router', () {
    Future<StackRouter> pushSubRoute(WidgetTester tester) async {
      unawaited(router.push(SecondHostRoute()));
      await tester.pumpAndSettle();
      final nested = router.innerRouterOf<StackRouter>(SecondHostRoute.name)!;
      unawaited(nested.push(const SecondNested3Route()));
      await tester.pumpAndSettle();
      expectTopPage(router, SecondNested3Route.name);
      return nested;
    }

    testWidgets('system back should pop only the sub-route, then the host route', (tester) async {
      await pumpRouterApp(tester, router);
      final nested = await pushSubRoute(tester);

      await systemBack(tester);

      expect(find.text(SecondNested3Route.name), findsNothing);
      expect(router.current.name, SecondHostRoute.name);
      expectTopPage(router, SecondNested1Route.name);
      expect(nested.stack.length, 1);

      await systemBack(tester);

      expectTopPage(router, FirstRoute.name);
    });

    testWidgets('iOS back swipe should pop only the sub-route, then the host route', (tester) async {
      await pumpIosApp(tester, router);
      final nested = await pushSubRoute(tester);

      await swipeBack(tester);

      expect(find.text(SecondNested3Route.name), findsNothing);
      expect(router.current.name, SecondHostRoute.name);
      expectTopPage(router, SecondNested1Route.name);
      expect(nested.stack.length, 1);

      await swipeBack(tester);

      expectTopPage(router, FirstRoute.name);
    });
  });

  // Same steps with a second level of nesting: Tab2Route is a nested router
  // inside SecondHostRoute's router and holds Tab2Nested1Route then
  // Tab2Nested2Route. Each back pops only the top-most route.
  group('with two levels of nested routers', () {
    Future<void> pushDeepRoutes(WidgetTester tester) async {
      unawaited(router.push(SecondHostRoute()));
      await tester.pumpAndSettle();
      final nested = router.innerRouterOf<StackRouter>(SecondHostRoute.name)!;
      unawaited(nested.push(const Tab2Route()));
      await tester.pumpAndSettle();
      unawaited(nested.innerRouterOf<StackRouter>(Tab2Route.name)!.push(const Tab2Nested2Route()));
      await tester.pumpAndSettle();
      expectTopPage(router, Tab2Nested2Route.name);
    }

    Future<void> expectBackSteps(WidgetTester tester, Future<void> Function(WidgetTester) back) async {
      await back(tester);
      expectTopPage(router, Tab2Nested1Route.name);
      await back(tester);
      expectTopPage(router, SecondNested1Route.name);
      await back(tester);
      expectTopPage(router, FirstRoute.name);
    }

    testWidgets('system back should pop one route at a time', (tester) async {
      await pumpRouterApp(tester, router);
      await pushDeepRoutes(tester);

      await expectBackSteps(tester, systemBack);
    });

    testWidgets('iOS back swipe should pop one route at a time', (tester) async {
      await pumpIosApp(tester, router);
      await pushDeepRoutes(tester);

      await expectBackSteps(tester, swipeBack);
    });
  });
}
