import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/pages.dart';

// System back pops the nested sub-route first.
// https://github.com/Milad-Akarie/auto_route_library/issues/1932
// Headless test: auto_route/test/nested_router/back_gesture_test.dart
//
// "System back" goes through the Android activity's back handler on Android
// (see systemBack); the swipe is the iOS edge swipe, run with the iOS page
// transitions on every platform, as the headless test does.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
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
      ],
    );
  });

  final iosTheme = ThemeData(platform: .iOS);

  // Steps: push SecondHostRoute (its nested router shows SecondNested1Route),
  // push SecondNested3Route into that nested router, then go back.
  // Should: only SecondNested3Route is popped; SecondHostRoute stays with
  // SecondNested1Route on screen. A second back pops SecondHostRoute.
  group('with a sub-route pushed in a nested router', () {
    Future<StackRouter> pushSubRoute(WidgetTester tester) async {
      unawaited(router.push(const SecondHostRoute()));
      await tester.pumpAndSettle();
      final nested = router.innerRouterOf<StackRouter>(SecondHostRoute.name)!;
      unawaited(nested.push(const SecondNested3Route()));
      await tester.pumpAndSettle();
      expectTopPage(router, SecondNested3Route.name);
      return nested;
    }

    testWidgets('system back pops only the sub-route, then the host route', (
      tester,
    ) async {
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

    testWidgets('iOS back swipe pops only the sub-route, then the host route', (
      tester,
    ) async {
      await pumpRouterApp(tester, router, theme: iosTheme);
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
      unawaited(router.push(const SecondHostRoute()));
      await tester.pumpAndSettle();
      final nested = router.innerRouterOf<StackRouter>(SecondHostRoute.name)!;
      unawaited(nested.push(const Tab2Route()));
      await tester.pumpAndSettle();
      unawaited(
        nested
            .innerRouterOf<StackRouter>(Tab2Route.name)!
            .push(const Tab2Nested2Route()),
      );
      await tester.pumpAndSettle();
      expectTopPage(router, Tab2Nested2Route.name);
    }

    Future<void> expectBackSteps(
      WidgetTester tester,
      Future<void> Function(WidgetTester) back,
    ) async {
      await back(tester);
      expectTopPage(router, Tab2Nested1Route.name);
      await back(tester);
      expectTopPage(router, SecondNested1Route.name);
      await back(tester);
      expectTopPage(router, FirstRoute.name);
    }

    testWidgets('system back pops one route at a time', (tester) async {
      await pumpRouterApp(tester, router);
      await pushDeepRoutes(tester);

      await expectBackSteps(tester, systemBack);
    });

    testWidgets('iOS back swipe pops one route at a time', (tester) async {
      await pumpRouterApp(tester, router, theme: iosTheme);
      await pushDeepRoutes(tester);

      await expectBackSteps(tester, swipeBack);
    });
  });
}
