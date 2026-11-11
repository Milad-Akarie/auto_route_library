import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/110149
  // In go_router, a pop from /bar/baz landed on /bar even after /bar's
  // redirect had started to send users away. In auto_route a pop runs no
  // guard by design; reevaluateListenable is how an app re-checks the pages it
  // shows.
  // Steps: allow BarRoute, open BarRoute with its child BazRoute on top of
  // FooRoute, then forbid BarRoute and fire reevaluateListenable.
  // Should: BarRoute and its child BazRoute both close; FooRoute shows.
  testWidgets(
    'Forbidding a guarded parent closes it and its child on reevaluation (flutter/flutter#110149)',
    (tester) async {
      final allowed = ValueNotifier(true);
      addTearDown(allowed.dispose);
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'FooRoute',
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('FooRoute')),
          ),
          NamedRouteDef(
            name: 'BarRoute',
            path: '/bar',
            guards: [
              AutoRouteGuard.simple(
                (resolver, _) =>
                    allowed.value ? resolver.next() : resolver.reject(),
              ),
            ],
            builder: (_, _) => const AutoRouter(),
            children: [
              NamedRouteDef(
                name: 'BazRoute',
                path: 'baz',
                builder: (_, _) => const Scaffold(body: Text('BazRoute')),
              ),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router, reevaluationNotifier: allowed);
      unawaited(router.pushPath('/bar/baz'));
      await tester.pumpAndSettle();
      expect(router.urlState.path, '/bar/baz');
      expect(find.text('BazRoute'), findsOneWidget);

      allowed.value = false;
      await tester.pumpAndSettle();

      expect(router.stack.map((e) => e.routeData.name), ['FooRoute']);
      expect(find.text('BazRoute'), findsNothing);
      expect(find.text('FooRoute'), findsOneWidget);
      expect(router.urlState.path, '/');
    },
  );
}
