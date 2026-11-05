import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/pages.dart';

// Overlapping guard reevaluations no longer crash.
// https://github.com/Milad-Akarie/auto_route_library/pull/2341
// Headless test:
// auto_route/test/reevaluatable_router/reevaluation_listener_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late ValueNotifier<bool> reevaluationNotifier;
  setUp(() => reevaluationNotifier = ValueNotifier(false));

  // Steps: push a page whose async guard is still pending, then call
  // reevaluateGuards three times before the first guard check finishes.
  // Should: no "Future already completed" crash; the guard runs once per
  // reevaluation, and the page shows once the guard passes.
  testWidgets(
    'Overlapping reevaluations wait for a running guard without crashing '
    '(#2341)',
    (tester) async {
      var calls = 0;
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(page: FirstRoute.page, initial: true),
          AutoRoute(
            page: SecondRoute.page,
            guards: [
              AutoRouteGuard.simple((resolver, router) async {
                calls++;
                await Future<void>.delayed(const Duration(milliseconds: 50));
                if (reevaluationNotifier.value) resolver.next();
              }),
            ],
          ),
        ],
      )..ignorePopCompleters = true;
      await pumpRouterApp(tester, router);
      unawaited(router.push(const SecondRoute()));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 200));
      expect(calls, 1);

      // Three passes reach the same pending resolver while the first one's
      // guard runs.
      unawaited(router.reevaluateGuards());
      unawaited(router.reevaluateGuards());
      unawaited(router.reevaluateGuards());
      await tester.pump(const Duration(milliseconds: 500));
      expect(calls, 4);

      reevaluationNotifier.value = true;
      unawaited(router.reevaluateGuards());
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expectTopPage(router, SecondRoute.name);
    },
  );
}
