import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// #1346: after logging in through a guard, navigate() to a child of the
// guarded shell changed the url but the shell kept showing its first child,
// until a hot reload.
// Steps: '/dashboard' is the initial route, has the children 'users'
// (initial) and 'another', and a guard that, while logged out, pushes
// LoginRoute and calls resolver.next() once that push completes. Login logs
// in and calls replace(DashboardRoute). Then navigate(AnotherRoute).
// Should: AnotherRoute shows in the dashboard and the url is
// '/dashboard/another'. The root stack then holds two dashboards, as the
// reporter's code asks: Login's replace opens one, and the guard, resumed
// when the replaced Login's push completes, opens the other.
void main() {
  testWidgets('navigate to a sibling child after login through the guard', (
    tester,
  ) async {
    var isLoggedIn = false;
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'LoginRoute',
          path: '/login',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () {
                isLoggedIn = true;
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
          path: '/dashboard',
          initial: true,
          guards: [
            AutoRouteGuard.simple((resolver, guardRouter) {
              if (isLoggedIn) {
                resolver.next();
              } else {
                unawaited(
                  guardRouter
                      .push(const NamedRoute('LoginRoute'))
                      .then((_) => resolver.next()),
                );
              }
            }),
          ],
          builder: (_, _) => Scaffold(
            appBar: AppBar(title: const Text('Menu')),
            body: const AutoRouter(),
          ),
          children: [
            NamedRouteDef(
              name: 'UsersRoute',
              path: 'users',
              initial: true,
              builder: (_, _) => const Text('Users'),
            ),
            NamedRouteDef(
              name: 'AnotherRoute',
              path: 'another',
              builder: (_, _) => const Text('Another'),
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    expect(find.text('Log in'), findsOneWidget);

    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Users'), findsOneWidget);

    unawaited(router.navigate(const NamedRoute('AnotherRoute')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(router.stack.map((page) => page.name), [
      'DashboardRoute',
      'DashboardRoute',
    ]);
    expect(router.urlState.path, '/dashboard/another');
    expect(find.text('Another'), findsOneWidget);
    expect(find.text('Users'), findsNothing);
  });
}
