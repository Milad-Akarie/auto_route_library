import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/141251
  // In go_router, the future of a push never completed once the pushed page
  // was replaced with pushReplacement.
  // Steps: from HomeRoute, keep the future of push(DetailsRoute); replace
  // DetailsRoute with Details2Route; then pop Details2Route.
  // Should: the future completes with null when DetailsRoute is replaced, as
  // Navigator.pushReplacement does, and the pop shows HomeRoute.
  testWidgets(
    'The future of a push completes with null once its page is replaced (flutter/flutter#141251)',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('HomeRoute')),
          ),
          NamedRouteDef(
            name: 'DetailsRoute',
            path: '/details',
            builder: (_, _) => const Scaffold(body: Text('Details')),
          ),
          NamedRouteDef(
            name: 'Details2Route',
            path: '/details2',
            builder: (_, _) => const Scaffold(body: Text('Details2')),
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      var completed = false;
      String? result = 'not completed';
      router.push<String>(const NamedRoute('DetailsRoute')).then((value) {
        completed = true;
        result = value;
      }).ignore();
      await tester.pumpAndSettle();

      unawaited(router.replace(const NamedRoute('Details2Route')));
      await tester.pumpAndSettle();
      expect(completed, isTrue);
      expect(result, isNull);
      expect(router.stack.map((e) => e.routeData.name), [
        'HomeRoute',
        'Details2Route',
      ]);

      router.pop();
      await tester.pumpAndSettle();
      expectTopPage(router, 'HomeRoute');
    },
  );
}
