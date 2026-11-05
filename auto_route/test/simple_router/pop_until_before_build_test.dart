import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// popUntil, popUntilRoot and popUntilRouteWithName called before the
// navigator has built the pages they close did nothing, and the pages
// stayed. This happens right after a push in the same frame, and as an app
// the platform ended and restored starts (see
// restoration/restore_then_pop_until_test.dart).
// Should: the pop waits for the navigator to build those pages, then closes
// them as it would a frame later.
void main() {
  late RootStackRouter router;

  setUp(() {
    router = RootStackRouter.build(
      routes: [
        for (final name in ['Home', 'List', 'Detail'])
          AutoRoute(page: _page(name), initial: name == 'Home'),
      ],
    );
  });

  // Steps: open Home, push List and Detail, and in the same frame, before
  // any frame builds them, call [popUntil].
  Future<String> pushTwoThenPop(
    WidgetTester tester,
    void Function() popUntil,
  ) async {
    await pumpRouterApp(tester, router);
    unawaited(router.push(const PageRouteInfo('List')));
    unawaited(router.push(const PageRouteInfo('Detail')));
    popUntil();
    await tester.pumpAndSettle();
    return router.stack.map((page) => page.name).join(', ');
  }

  testWidgets('popUntil right after two pushes', (tester) async {
    expect(
      await pushTwoThenPop(
        tester,
        () => router.popUntil((route) => route.isFirst),
      ),
      'Home',
    );
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('popUntilRoot right after two pushes', (tester) async {
    expect(await pushTwoThenPop(tester, router.popUntilRoot), 'Home');
  });

  testWidgets('popUntilRouteWithName right after two pushes', (tester) async {
    expect(
      await pushTwoThenPop(tester, () => router.popUntilRouteWithName('List')),
      'Home, List',
    );
  });

  // Steps: open Home and List, push Detail, and in the same frame pop until
  // List: Detail, which no frame has built yet, is the page to close.
  testWidgets('popUntil closes a page pushed this frame', (tester) async {
    await pumpRouterApp(tester, router);
    unawaited(router.push(const PageRouteInfo('List')));
    await tester.pumpAndSettle();
    unawaited(router.push(const PageRouteInfo('Detail')));
    router.popUntil((route) => route.settings.name == 'List');
    await tester.pumpAndSettle();
    expect(
      (
        router.stack.map((page) => page.name).join(', '),
        find.text('Detail').evaluate().length,
      ),
      ('Home, List', 0),
    );
  });
}

PageInfo _page(String name) => .new(name, builder: (_) => Text(name));
