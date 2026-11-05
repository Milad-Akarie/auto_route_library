import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/140510
  // In go_router, a pop and a refreshListenable redirect that returned null,
  // in the same frame, reopened the popped route.
  // Steps: a global guard always calls next(); push SecondRoute, then in one
  // callback pop it and fire reevaluateListenable.
  // Should: SecondRoute stays closed; HomeRoute shows.
  final pops =
      <String, void Function(StackRouter router, BuildContext context)>{
        'router.pop()': (router, _) => router.pop(),
        'Navigator.pop()': (_, context) => Navigator.of(context).pop(),
      };
  for (final MapEntry(key: name, value: pop) in pops.entries) {
    testWidgets(
      'A page popped with $name as reevaluateListenable fires stays closed (flutter/flutter#140510)',
      (tester) async {
        final user = ValueNotifier(0);
        addTearDown(user.dispose);
        final router = RootStackRouter.build(
          guards: [AutoRouteGuard.simple((resolver, _) => resolver.next())],
          routes: [
            NamedRouteDef(
              name: 'HomeRoute',
              path: '/',
              builder: (_, _) => const Scaffold(body: Text('HomeRoute')),
            ),
            NamedRouteDef(
              name: 'SecondRoute',
              path: '/second',
              builder: (_, _) => const Scaffold(body: Text('SecondRoute')),
            ),
          ],
        );
        await pumpRouterApp(tester, router, reevaluationNotifier: user);
        unawaited(router.pushPath('/second'));
        await tester.pumpAndSettle();

        pop(router, tester.element(find.text('SecondRoute')));
        user.value++;
        await tester.pumpAndSettle();

        expect(router.stack.map((e) => e.routeData.name), ['HomeRoute']);
        expect(find.text('SecondRoute'), findsNothing);
      },
    );
  }
}
