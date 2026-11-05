import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/106166
  // In go_router, setting refreshListenable broke the back button.
  // Steps: open HomeRoute with reevaluateListenable set, push
  // SecondRoute, fire the listenable, tap SecondRoute's AppBar back button, then fire the
  // listenable again.
  // Should: SecondRoute closes and HomeRoute stays, with no error.
  testWidgets(
    'The back button pops a page while reevaluateListenable is set (flutter/flutter#106166)',
    (tester) async {
      final user = ValueNotifier(0);
      addTearDown(user.dispose);
      final router = RootStackRouter.build(
        guards: [AutoRouteGuard.simple((resolver, _) => resolver.next())],
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('HomeRoute')),
          ),
          NamedRouteDef(
            name: 'SecondRoute',
            path: '/second',
            builder: (_, _) =>
                Scaffold(appBar: AppBar(), body: const Text('SecondRoute')),
          ),
        ],
      );
      await pumpRouterApp(tester, router, reevaluationNotifier: user);
      unawaited(router.pushPath('/second'));
      await tester.pumpAndSettle();
      user.value++;
      await tester.pumpAndSettle();
      expectTopPage(router, 'SecondRoute');

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      user.value++;
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(router.stack.map((e) => e.routeData.name), ['HomeRoute']);
      expect(find.text('HomeRoute'), findsOneWidget);
    },
  );
}
