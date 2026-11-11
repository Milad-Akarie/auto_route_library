import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// flutter/flutter#146938: in go_router, pushing a page, popping it 100 ms
// later while it was still animating in, and going to another page in the
// same call threw "Bad state: Future already completed".
// Steps: on A, push A again without awaiting it; after a delay shorter than
// the transition, pop and, in the same call, open B with replaceAll (as go
// does) or navigate.
// Should: nothing throws, B shows, and the awaited push of A completes once.
void main() {
  final opens = {
    'replaceAll': (
      (StackRouter router) =>
          unawaited(router.replaceAll([const NamedRoute('BRoute')])),
      ['BRoute'],
    ),
    'navigate': (
      (StackRouter router) =>
          unawaited(router.navigate(const NamedRoute('BRoute'))),
      ['ARoute', 'BRoute'],
    ),
  };

  for (final MapEntry(key: name, value: (open, stack)) in opens.entries) {
    for (final delay in [0, 16, 100, 200]) {
      testWidgets('push, pop after $delay ms, then $name in the same call', (
        tester,
      ) async {
        final router = RootStackRouter.build(
          routes: [
            NamedRouteDef(
              name: 'ARoute',
              path: '/',
              initial: true,
              builder: (_, _) => const Scaffold(body: Text('A')),
            ),
            NamedRouteDef(
              name: 'BRoute',
              path: '/b',
              builder: (_, _) => const Scaffold(body: Text('B')),
            ),
          ],
        );
        await pumpRouterApp(tester, router);
        var completions = 0;
        Object? error;
        unawaited(
          router
              .push<void>(const NamedRoute('ARoute'))
              .then<void>((_) => completions++)
              .catchError((Object e) => error = e),
        );
        await tester.pump(Duration(milliseconds: delay));
        router.pop();
        open(router);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(error, isNull);
        expect(completions, 1);
        expect(router.stack.map((page) => page.name), stack);
        expect(find.text('B'), findsOneWidget);
      });
    }
  }
}
