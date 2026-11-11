import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'back_test_utils.dart';
import 'router_test_utils.dart';

// Reported as https://github.com/Milad-Akarie/auto_route_library/issues/1970
// Setup: iOS (swipe back), pages A and C are AutoRoutes, B is a CustomRoute
// (no builder given, so the default transition); the flow is A -> B -> C.
// Steps: from C, swipe back to B; do it again two or three times, also
// letting go before the swipe is far enough and swiping again at once.
// Happened: after a few swipes the UI went back to A.
// Should: every swipe from C shows B, and A only shows after a swipe from B.
void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('A'), path: '/', initial: true),
        CustomRoute(page: _page('B'), path: '/b'),
        AutoRoute(page: _page('C'), path: '/c'),
      ],
    );
  });

  Future<void> openC(WidgetTester tester) async {
    unawaited(router.push(const NamedRoute('C')));
    await tester.pumpAndSettle();
    expectCurrentPage(router, 'C');
  }

  Future<void> pumpIosApp(WidgetTester tester) async {
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: iosTheme, routerConfig: router.config()),
    );
    await tester.pumpAndSettle();
    unawaited(router.push(const NamedRoute('B')));
    await tester.pumpAndSettle();
  }

  testWidgets('swiping back from C to B four times in a row stays on B', (
    tester,
  ) async {
    await pumpIosApp(tester);

    for (var i = 0; i < 4; i++) {
      await openC(tester);
      await swipeBack(tester);
      expectCurrentPage(router, 'B');
      expect(router.stack.map((page) => page.routeData.name), ['A', 'B']);
    }
  });

  testWidgets('an unfinished swipe, then another, ends on B', (tester) async {
    await pumpIosApp(tester);
    await openC(tester);

    for (var i = 0; i < 3; i++) {
      // Let go before the swipe is far enough: the page springs back.
      await tester.dragFrom(const Offset(2, 300), const Offset(60, 0));
      await tester.pumpAndSettle();
      expectCurrentPage(router, 'C');
    }
    // Two swipes without waiting for the first to finish.
    Future<void> flick() async {
      final gesture = await tester.startGesture(const Offset(2, 300));
      await gesture.moveBy(const Offset(500, 0));
      await gesture.up();
    }

    await flick();
    await tester.pump(const Duration(milliseconds: 50));
    await flick();
    await tester.pumpAndSettle();

    expect(router.stack.map((page) => page.routeData.name), ['A', 'B']);
    expectCurrentPage(router, 'B');
  });
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));
