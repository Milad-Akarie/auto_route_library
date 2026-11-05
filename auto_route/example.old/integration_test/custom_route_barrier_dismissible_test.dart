import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A CustomRoute with barrierDismissible: true pops on a barrier tap.
// https://github.com/flutter/flutter/issues/102289
// Headless test: auto_route/test/custom_route_barrier_dismissible_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: a CustomRoute with opaque: false, barrierDismissible: true and a
  // barrier color shows a small card over the home page. Tap outside the card.
  // Should: the card's route pops and the home page stays.
  testWidgets(
    'Tapping the barrier of a barrierDismissible CustomRoute pops it',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            page: PageInfo(
              'HomeRoute',
              builder: (_) => const Scaffold(body: Text('HomeRoute')),
            ),
            path: '/',
          ),
          CustomRoute(
            page: PageInfo(
              'CardRoute',
              builder: (_) => const Center(
                child: SizedBox.square(
                  dimension: 100,
                  child: Card(child: Text('CardRoute')),
                ),
              ),
            ),
            path: '/card',
            opaque: false,
            barrierDismissible: true,
            barrierColor: Colors.black54,
          ),
        ],
      );
      await pumpRouterAppWithConfig(tester, router);
      unawaited(router.push(const NamedRoute('CardRoute')));
      await tester.pumpAndSettle();
      expect(find.text('CardRoute'), findsOneWidget);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(router.stack.map((page) => page.name), ['HomeRoute']);
      expect(find.text('CardRoute'), findsNothing);
    },
  );
}
