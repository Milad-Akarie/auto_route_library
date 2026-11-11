import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/133985
  // In go_router, a redirect run by refreshListenable got the state of the
  // bottom page of the stack, not of the page the user was on.
  // Steps: a global guard records the name and path of each route it
  // checks; open HomeRoute, push SecondRoute, then fire reevaluateListenable.
  // Should: the re-check runs for each page with its own route and path.
  testWidgets(
    'A reevaluation checks each page with its own route and path (flutter/flutter#133985)',
    (tester) async {
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
    },
  );

  // https://github.com/flutter/flutter/issues/162735
  // In go_router, after a push, refreshListenable redirected with the state of
  // the page below. Steps: guards on HomeRoute and SecondRoute record the route
  // they check, then open HomeRoute, push SecondRoute, then fire
  // reevaluateListenable. Should: each guard checks its own page, and the stack
  // stays HomeRoute and SecondRoute with SecondRoute on screen.
  testWidgets(
    'After a push, a reevaluation checks each page and keeps the stack (flutter/flutter#162735)',
    (tester) async {
      final user = ValueNotifier(0);
      addTearDown(user.dispose);
      final checked = <String>[];
      AutoRouteGuard record(String owner) => .simple((resolver, _) {
        checked.add('$owner ${resolver.route.name} ${resolver.route.fullPath}');
        resolver.next();
      });
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            guards: [record('home guard')],
            builder: (_, _) => const Scaffold(body: Text('HomeRoute')),
          ),
          NamedRouteDef(
            name: 'SecondRoute',
            path: '/second',
            guards: [record('second guard')],
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

      expect(checked, [
        'home guard HomeRoute /',
        'second guard SecondRoute /second',
      ]);
      expect(router.stack.map((e) => e.routeData.name), [
        'HomeRoute',
        'SecondRoute',
      ]);
      expectTopPage(router, 'SecondRoute');
    },
  );
}
