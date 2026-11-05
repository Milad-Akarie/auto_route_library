@TestOn('browser')
library;

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'browser_history.dart';

void main() {
  useRealBrowserHistory();
  setUp(rewindBrowserHistory);

  // https://github.com/flutter/flutter/issues/149181
  // In go_router, a page pushed with push() and reached again with the
  // browser's forward button ran its redirect without following it.
  // Steps: open HomeRoute, push LoginRoute, whose guard lets a logged-out user
  // through and keeps a logged-in one away, log in, press the browser's back
  // button, then its forward button.
  // Should: the forward button runs LoginRoute's guard again, which keeps the
  // user on HomeRoute: LoginRoute is neither on screen nor in the stack.
  final guards = <String, AutoRouteGuard Function(ValueGetter<bool> loggedIn)>{
    'reject()': (loggedIn) => AutoRouteGuard.simple((resolver, _) => loggedIn() ? resolver.reject() : resolver.next()),
    'AutoRouteGuard.redirect()': (loggedIn) =>
        AutoRouteGuard.redirect((_) => loggedIn() ? const NamedRoute('HomeRoute') : null),
  };
  for (final MapEntry(key: name, value: guard) in guards.entries) {
    testWidgets('On web, the browser forward button to a guarded page runs its guard again, with $name '
        '(flutter/flutter#149181)', (tester) async {
      var loggedIn = false;
      var guardCalls = 0;
      final loginGuard = guard(() {
        guardCalls++;
        return loggedIn;
      });
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('HomeRoute')),
          ),
          NamedRouteDef(
            name: 'LoginRoute',
            path: '/login',
            guards: [loginGuard],
            builder: (_, _) => const Scaffold(body: Text('LoginRoute')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config()));
      await settleBrowser(tester);

      unawaited(router.pushPath('/login'));
      await settleBrowser(tester);
      expect(find.text('LoginRoute'), findsOneWidget);
      expect(browserPath, '/login');
      loggedIn = true;

      await pressBrowserBack(tester);
      expect(find.text('HomeRoute'), findsOneWidget);
      expect(browserPath, '/');

      await pressBrowserForward(tester);
      expect(guardCalls, 2);
      expect(find.text('LoginRoute'), findsNothing);
      expect(find.text('HomeRoute'), findsOneWidget, reason: 'after pressBrowserForward(tester)');
      expect(router.stack.map((e) => e.routeData.name), isNot(contains('LoginRoute')));
      expect(router.topRoute.name, 'HomeRoute');
    });
  }
}
