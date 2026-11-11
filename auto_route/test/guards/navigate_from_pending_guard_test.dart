import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// #1206: the report said navigate skipped guards; today navigate runs them
// (see blocked_link_keeps_stack_test.dart). The comment's case: a guard that
// calls router.navigate(LoginRoute) while its own navigation is still
// pending saw no effect, where push worked.
// Steps: from Home, push ProtectedRoute, whose guard, while logged out, opens
// LoginRoute with navigate (or push) and waits; on Login, log in, which
// calls resolver.next() and closes Login.
// Should: Login shows while the guard waits, then ProtectedRoute shows over
// Home.
void main() {
  final opens = <String, Future<void> Function(StackRouter, PageRouteInfo)>{
    'navigate': (router, route) => router.navigate(route),
    'push': (router, route) => router.push(route),
  };

  for (final MapEntry(key: name, value: open) in opens.entries) {
    testWidgets('a pending guard that opens login with $name', (tester) async {
      NavigationResolver? pending;
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            initial: true,
            builder: (_, _) => const Scaffold(body: Text('Home')),
          ),
          NamedRouteDef(
            name: 'LoginRoute',
            path: '/login',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () {
                  pending!.next();
                  context.router.removeWhere(
                    (route) => route.name == 'LoginRoute',
                  );
                },
                child: const Text('Log in'),
              ),
            ),
          ),
          NamedRouteDef(
            name: 'ProtectedRoute',
            path: '/protected',
            guards: [
              AutoRouteGuard.simple((resolver, guardRouter) {
                pending = resolver;
                unawaited(open(guardRouter, const NamedRoute('LoginRoute')));
              }),
            ],
            builder: (_, _) => const Scaffold(body: Text('Protected')),
          ),
        ],
      );
      await pumpRouterApp(tester, router);

      unawaited(router.push(const NamedRoute('ProtectedRoute')));
      await tester.pumpAndSettle();
      expect(router.topRoute.name, 'LoginRoute');
      expect(find.text('Log in'), findsOneWidget);

      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(router.stack.map((page) => page.name), [
        'HomeRoute',
        'ProtectedRoute',
      ]);
      expect(find.text('Protected'), findsOneWidget);
    });
  }
}
