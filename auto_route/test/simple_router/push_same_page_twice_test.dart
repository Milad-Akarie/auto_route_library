import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

import '../centered_named_page.dart';
import '../router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/107045
  // Pushing the same page twice, with equal arguments, failed the assertion
  // '!keyReservation.contains(key)'. Both pages stay, and each pop removes one.
  testWidgets(
    'The same page pushed twice stays twice and pops one at a time (flutter/flutter#107045)',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            builder: (_, _) => const CenteredNamedPage('HomeRoute'),
          ),
          NamedRouteDef(
            name: 'ItemRoute',
            path: '/item',
            builder: (_, _) => const CenteredNamedPage('ItemRoute'),
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      unawaited(router.push(const NamedRoute('ItemRoute')));
      await tester.pumpAndSettle();
      unawaited(router.push(const NamedRoute('ItemRoute')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(router.stack.map((e) => e.name), [
        'HomeRoute',
        'ItemRoute',
        'ItemRoute',
      ]);

      router.pop();
      await tester.pumpAndSettle();
      expect(router.stack.map((e) => e.name), ['HomeRoute', 'ItemRoute']);
      router.pop();
      await tester.pumpAndSettle();
      expect(router.stack.map((e) => e.name), ['HomeRoute']);
    },
  );
}
