import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

class _Auth extends ChangeNotifier {
  bool isLoggedIn = false;

  Future<void> tryAutoLogin() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    isLoggedIn = true;
    notifyListeners();
  }
}

void main() {
  // https://github.com/flutter/flutter/issues/112798
  // In go_router, an async redirect that awaited an auto login, which
  // notified the router's refreshListenable, threw a RangeError.
  // Steps: open the app with a global guard that, while logged out, awaits
  // tryAutoLogin(), which logs in and notifies reevaluateListenable, then
  // calls next(); push SecondRoute.
  // Should: no error, the guard runs a bounded number of times and the stack
  // settles on HomeRoute, SecondRoute.
  testWidgets(
    'A guard that notifies reevaluateListenable while it waits settles (flutter/flutter#112798)',
    (tester) async {
      final auth = _Auth();
      addTearDown(auth.dispose);
      var guardCalls = 0;
      final router = RootStackRouter.build(
        guards: [
          AutoRouteGuard.simple((resolver, _) async {
            guardCalls++;
            if (!auth.isLoggedIn) await auth.tryAutoLogin();
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
      await pumpRouterApp(tester, router, reevaluationNotifier: auth);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expectTopPage(router, 'HomeRoute');

      unawaited(router.pushPath('/second'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(router.stack.map((e) => e.routeData.name), [
        'HomeRoute',
        'SecondRoute',
      ]);
      expect(find.text('SecondRoute'), findsOneWidget);
      // HomeRoute's first check, the re-check of HomeRoute the login fired, and
      // SecondRoute's.
      expect(guardCalls, lessThanOrEqualTo(3));
    },
  );
}
