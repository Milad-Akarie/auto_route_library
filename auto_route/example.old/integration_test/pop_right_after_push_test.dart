import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// pop right after push pops the pushed page, not the one below it.
// flutter/flutter#145573
// Headless test: auto_route/test/simple_router/pop_right_after_push_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('A'), path: '/', initial: true),
        AutoRoute(page: _page('B'), path: '/b'),
        AutoRoute(page: _page('C'), path: '/c'),
      ],
    );
  });

  List<String> names() =>
      router.stack.map((page) => page.routeData.name).toList();

  // Steps: on A, tap a button that calls push(B) then pop().
  // Should: B is popped and A stays, with no exception.
  testWidgets("The reporter's button: push then pop on the first page", (
    tester,
  ) async {
    await pumpRouterApp(tester, router);

    await tester.tap(find.text('Push and pop'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(names(), ['A']);
    expectCurrentPage(router, 'A');
  });

  // Steps: open A, then C; tap C's button, which calls push(B) then pop().
  // Should: the stack is [A, C] again, with C on screen.
  testWidgets(
    'push then pop over a pushed page leaves that page',
    (tester) async {
      await pumpRouterApp(tester, router);
      unawaited(router.push(const PageRouteInfo('C')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Push and pop'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(names(), ['A', 'C']);
      expectCurrentPage(router, 'C');
    },
  );
}

PageInfo _page(String name) => .new(
  name,
  builder: (_) => Scaffold(
    body: SafeArea(
      child: Builder(
        builder: (context) => Column(
          children: [
            Text(name),
            TextButton(
              onPressed: () {
                unawaited(context.router.push(const PageRouteInfo('B')));
                context.router.pop();
              },
              child: const Text('Push and pop'),
            ),
          ],
        ),
      ),
    ),
  ),
);
