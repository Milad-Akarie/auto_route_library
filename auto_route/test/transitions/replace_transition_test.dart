import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/138320
  // In go_router, pushReplacement showed no transition when both pages had a
  // custom page builder, though push slid the page in.
  // Steps: Home, A and B are CustomRoutes that slide in from the left over
  // 400 ms. Open Home, push A, then replace A with B; check B half way.
  // Should: B slides in on replace as A did on push.
  testWidgets('replace() plays the slide transition of the new CustomRoute (flutter/flutter#138320)', (tester) async {
    CustomRoute sliding(String name, String path) => .new(
      page: PageInfo(name, builder: (_) => Scaffold(body: Text(name))),
      path: path,
      transitionsBuilder: TransitionsBuilders.slideLeft,
      duration: const Duration(milliseconds: 400),
    );
    final router = RootStackRouter.build(routes: [sliding('Home', '/'), sliding('A', '/a'), sliding('B', '/b')]);
    await pumpRouterApp(tester, router);
    final screenWidth = tester.getSize(find.byType(Scaffold)).width;

    unawaited(router.push(const NamedRoute('A')));
    await tester.pump(.zero);
    await tester.pump(const Duration(milliseconds: 200));
    final pushLeft = tester.getTopLeft(find.text('A')).dx;
    expect(pushLeft, inExclusiveRange(0, screenWidth));
    await tester.pumpAndSettle();

    unawaited(router.replace(const NamedRoute('B')));
    await tester.pump(.zero);
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.getTopLeft(find.text('B')).dx, moreOrLessEquals(pushLeft));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('B')).dx, 0);
    expect(router.stack.map((page) => page.name), ['Home', 'B']);
  });
}
