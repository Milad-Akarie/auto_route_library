import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  Widget argsPage(String name, RouteData<dynamic> data) => Scaffold(body: Text('$name ${data.args}'));

  // https://github.com/flutter/flutter/issues/146616
  // In go_router, the extra of a route was null once a redirect had run.
  // Steps: push ItemRoute with args 'first'; its guard either calls
  // overrideNext(args: 'override') or redirects with redirectUntil(LoginRoute)
  // and lets ItemRoute through once LoginRoute calls next().
  // Should: overrideNext builds ItemRoute with 'override'; after the redirect,
  // ItemRoute builds with its own args 'first'.
  testWidgets('overrideNext(args:) builds the page with the new args (flutter/flutter#146616)', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'HomeRoute',
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('HomeRoute')),
        ),
        NamedRouteDef(
          name: 'ItemRoute',
          path: '/item',
          guards: [AutoRouteGuard.simple((resolver, _) => resolver.overrideNext(args: 'override'))],
          builder: (_, data) => argsPage('ItemRoute', data),
        ),
      ],
    );
    await pumpRouterApp(tester, router);

    unawaited(router.push(const NamedRoute('ItemRoute', args: 'first')));
    await tester.pumpAndSettle();

    expect(find.text('ItemRoute override'), findsOneWidget);
  });

  testWidgets('A route let through after redirectUntil keeps its own args (flutter/flutter#146616)', (tester) async {
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
          builder: (_, data) => Scaffold(
            body: TextButton(onPressed: data.args! as VoidCallback, child: const Text('LoginRoute')),
          ),
        ),
        NamedRouteDef(
          name: 'ItemRoute',
          path: '/item',
          guards: [
            AutoRouteGuard.simple((resolver, _) {
              unawaited(resolver.redirectUntil(NamedRoute('LoginRoute', args: resolver.next)));
            }),
          ],
          builder: (_, data) => argsPage('ItemRoute', data),
        ),
      ],
    );
    await pumpRouterApp(tester, router);

    unawaited(router.push(const NamedRoute('ItemRoute', args: 'first')));
    await tester.pumpAndSettle();
    expectTopPage(router, 'LoginRoute');
    await tester.tap(find.text('LoginRoute'));
    await tester.pumpAndSettle();

    expect(router.stack.map((e) => e.routeData.name), ['HomeRoute', 'ItemRoute']);
    expect(find.text('ItemRoute first'), findsOneWidget);
  });
}
