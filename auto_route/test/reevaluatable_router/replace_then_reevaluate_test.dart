import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';
import 'auth_state.dart';

// flutter/flutter#149951: in go_router, logging in with context.replace while
// the auth state was the router's refresh listenable threw "Location cannot
// be empty", and the refresh listenable stopped working.
// Steps: the auth state is the reevaluateListenable, and the guarded
// Dashboard sends a logged-out user to Login with reject and replaceAll, as
// the README shows. On Login, log in, which notifies the listenable, then call
// replace(DashboardRoute) in the same callback. Then log out, and log in
// again.
// Should: nothing throws. After logging in only Dashboard is left, at '/'.
// Logging out goes back to Login alone, so the listenable still works, and
// logging in again shows Dashboard alone.
void main() {
  testWidgets('replace right after the listenable fires, then reevaluate', (
    tester,
  ) async {
    final auth = AuthState();
    addTearDown(auth.dispose);
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'LoginRoute',
          path: '/login',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () {
                auth.isLoggedIn = true;
                unawaited(
                  context.router.replace(const NamedRoute('DashboardRoute')),
                );
              },
              child: const Text('Log in'),
            ),
          ),
        ),
        NamedRouteDef(
          name: 'DashboardRoute',
          path: '/',
          initial: true,
          guards: [
            AutoRouteGuard.simple((resolver, guardRouter) {
              if (auth.isLoggedIn) {
                resolver.next();
              } else {
                resolver.reject();
                unawaited(
                  guardRouter.replaceAll([const NamedRoute('LoginRoute')]),
                );
              }
            }),
          ],
          builder: (_, _) => const Scaffold(body: Text('Dashboard')),
        ),
      ],
    );
    await pumpRouterApp(tester, router, reevaluationNotifier: auth);
    expect(router.stack.map((page) => page.name), ['LoginRoute']);

    for (var round = 0; round < 2; round++) {
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();
      final afterLogin = router.stack.map((page) => page.name);
      expect(afterLogin, ['DashboardRoute'], reason: 'round $round');
      expect(router.urlState.path, '/', reason: 'round $round');
      expect(find.text('Dashboard'), findsOneWidget, reason: 'round $round');

      auth.isLoggedIn = false;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final afterLogout = router.stack.map((page) => page.name);
      expect(afterLogout, ['LoginRoute'], reason: 'round $round');
      expect(find.text('Log in'), findsOneWidget, reason: 'round $round');
    }
  });
}
