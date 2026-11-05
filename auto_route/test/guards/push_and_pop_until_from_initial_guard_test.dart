import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/1010
  // Reported: calling router.pushAndPopUntil(LoginRoute(), predicate: (_) =>
  // false) from a guard on cold start, before any page showed, threw
  // "setState() or markNeedsBuild() called during build".
  // Steps: the first page's guard calls
  // pushAndPopUntil(LoginRoute(), predicate: (_) => false) and leaves its resolver waiting.
  // Should: no error, and LoginRoute shows alone.
  testWidgets('pushAndPopUntil from the guard of the first page on cold start shows the page', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef.guarded(
          name: 'HomeRoute',
          path: '/',
          onNavigation: (resolver, guardedRouter) {
            unawaited(guardedRouter.pushAndPopUntil(const NamedRoute('LoginRoute'), predicate: (_) => false));
          },
          builder: (_, _) => const Scaffold(body: Text('HomeRoute')),
        ),
        NamedRouteDef(
          name: 'LoginRoute',
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('LoginRoute')),
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());

    expect(tester.takeException(), isNull);
    expect(router.stack.map((p) => p.name), ['LoginRoute']);
    expect(find.text('LoginRoute'), findsOneWidget);
  });
}
