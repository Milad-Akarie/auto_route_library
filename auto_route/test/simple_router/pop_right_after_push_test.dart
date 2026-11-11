import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// flutter/flutter#145573: a page is pushed and popped before the push has
// settled, as when a loading page is closed after a quick task.
// The reporter's steps: on page A, a button calls push(B) then pop(). B
// should be popped, and the stack left as it was before the push. pop()
// popped the page below B instead, since B was added a microtask later.
void main() {
  late RootStackRouter router;

  RootStackRouter buildRouter({List<AutoRouteGuard> guardsOfB = const []}) =>
      .build(
        routes: [
          AutoRoute(page: _page('A'), initial: true),
          AutoRoute(page: _page('B'), guards: guardsOfB),
          AutoRoute(page: _page('C')),
        ],
      );

  List<String> names() =>
      router.stack.map((page) => page.routeData.name).toList();

  Future<void> openAThenC(WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    unawaited(router.push(const PageRouteInfo('C')));
    await tester.pumpAndSettle();
  }

  testWidgets("The reporter's button: push then pop on the first page", (
    tester,
  ) async {
    router = buildRouter();
    await pumpRouterApp(tester, router);

    await tester.tap(find.text('Push and pop'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(names(), ['A']);
    expectTopPage(router, 'A');
  });

  testWidgets(
    'pop right after push pops the pushed page and completes it with the '
    'result',
    (tester) async {
      router = buildRouter();
      await openAThenC(tester);

      String? result;
      unawaited(
        router
            .push<String>(const PageRouteInfo('B'))
            .then((value) => result = value),
      );
      router.pop('closed');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(result, 'closed');
      expect(names(), ['A', 'C']);
      expectTopPage(router, 'C');
    },
  );

  testWidgets('maybePop right after push pops the pushed page', (tester) async {
    router = buildRouter();
    await openAThenC(tester);

    unawaited(router.push(const PageRouteInfo('B')));
    final wasPopped = router.maybePop();
    await tester.pumpAndSettle();

    expect(await wasPopped, isTrue);
    expect(names(), ['A', 'C']);
    expectTopPage(router, 'C');
  });

  testWidgets(
    'pop after a quick task that follows the push pops the pushed page',
    (tester) async {
      router = buildRouter();
      await openAThenC(tester);

      unawaited(router.push(const PageRouteInfo('B')));
      await Future<void>.value();
      router.pop();
      await tester.pumpAndSettle();

      expect(names(), ['A', 'C']);
      expectTopPage(router, 'C');
    },
  );

  // Decided: a pop does not wait for a push whose guard is still
  // deciding, since the guard may be waiting on the very route the pop closes,
  // such as a dialog. The pop acts on the stack as it is, and B lands after it.
  testWidgets('pop during a push whose guard is deciding pops the page below', (
    tester,
  ) async {
    router = buildRouter(
      guardsOfB: [
        AutoRouteGuardCallback((resolver, _) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          resolver.next();
        }),
      ],
    );
    await openAThenC(tester);

    unawaited(router.push(const PageRouteInfo('B')));
    router.pop();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(names(), ['A', 'B']);
    expectTopPage(router, 'B');
  });
}

PageInfo _page(String name) => .new(
  name,
  builder: (_) => Scaffold(
    body: Builder(
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
);
