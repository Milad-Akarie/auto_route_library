import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// flutter/flutter#148185: the route list read right after pop() was not
// updated yet, so a loop popping until a page never ended.
// Steps: open Home, A, B and C; pop while the current page is not Home and
// the router can pop. The loop should end on Home after three pops. Same
// with popUntilRouteWithName('Home').
void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('Home'), initial: true),
        AutoRoute(page: _page('A')),
        AutoRoute(page: _page('B')),
        AutoRoute(page: _page('C')),
      ],
    );
  });

  Future<void> openStack(WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    for (final name in ['A', 'B', 'C']) {
      unawaited(router.push(PageRouteInfo(name)));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('a loop of pops until Home ends on Home after three pops', (
    tester,
  ) async {
    await openStack(tester);

    var pops = 0;
    while (router.current.name != 'Home' && router.canPop() && pops < 10) {
      router.pop();
      pops++;
    }
    await tester.pumpAndSettle();

    expect(pops, 3);
    expect(router.stack.map((page) => page.routeData.name), ['Home']);
    expectTopPage(router, 'Home');
  });

  testWidgets("popUntilRouteWithName('Home') ends on Home", (tester) async {
    await openStack(tester);

    router.popUntilRouteWithName('Home');
    await tester.pumpAndSettle();

    expect(router.stack.map((page) => page.routeData.name), ['Home']);
    expectTopPage(router, 'Home');
  });
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));
