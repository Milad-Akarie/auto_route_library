import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/133985
  // In go_router, a redirect run by refreshListenable got the state of the
  // bottom page of the stack, not of the page the user was on.
  // Steps: a global guard records the name and path of each route it checks;
  // open HomeRoute, push SecondRoute, then fire reevaluateListenable.
  // Should: the re-check runs for each page with its own route and path.
  testWidgets('A reevaluation checks each page with its own route and path (flutter/flutter#133985)', (tester) async {
    final user = ValueNotifier(0);
    addTearDown(user.dispose);
    final checked = <String>[];
    final router = RootStackRouter.build(
      guards: [
        AutoRouteGuard.simple((resolver, _) {
          checked.add('${resolver.route.name} ${resolver.route.fullPath}');
          resolver.next();
        }),
      ],
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
    checked.clear();

    user.value++;
    await tester.pumpAndSettle();

    expect(checked, ['HomeRoute /', 'SecondRoute /second']);
  });
}
