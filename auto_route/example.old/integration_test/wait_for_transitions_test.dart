import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/page_kinds_router.dart';

// router.waitForTransitions() completes once the pages have stopped moving.
// https://github.com/flutter/flutter/issues/162789, asked of go_router.
// Headless test: auto_route/test/transitions/wait_for_transitions_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const duration = Duration(milliseconds: 600);

  Animation<double> animationOf(WidgetTester tester, String name) {
    return ModalRoute.of(tester.element(find.text(name, skipOffstage: false)))!
        .animation!;
  }

  // Pumps frames until [done] completes; fails after five times the
  // transition's duration.
  Future<void> pumpUntilDone(WidgetTester tester, Future<void> done) async {
    var isDone = false;
    unawaited(done.then((_) => isDone = true));
    final stopwatch = Stopwatch()..start();
    while (!isDone) {
      if (stopwatch.elapsed > duration * 5) {
        fail('waitForTransitions() did not complete');
      }
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  // Steps: push CustomKindRoute, which fades in over 600 ms, without awaiting
  // the push; await router.waitForTransitions(). Then replace it with
  // MaterialKindRoute and wait again; then pop and wait again.
  // Should: each wait completes with the page's route animation
  // completed, and after the pop, dismissed.
  testWidgets(
    'waitForTransitions() completes once a push, a replace and a pop have '
    'ended',
    (tester) async {
      final router = pageKindsRouter(
        customTransitionsBuilder: TransitionsBuilders.fadeIn,
        customDuration: duration,
      );
      await pumpRouterApp(tester, router);

      unawaited(router.push(const NamedRoute('CustomKindRoute')));
      await pumpUntilDone(tester, router.waitForTransitions());
      expect(
        animationOf(tester, 'CustomKindRoute').status,
        AnimationStatus.completed,
      );

      unawaited(router.replace(const NamedRoute('MaterialKindRoute')));
      await pumpUntilDone(tester, router.waitForTransitions());
      final replaced = animationOf(tester, 'MaterialKindRoute');
      expect(replaced.status, AnimationStatus.completed);

      router.pop();
      await pumpUntilDone(tester, router.waitForTransitions());
      expect(replaced.status, AnimationStatus.dismissed);
      expectTopPage(router, 'HomeRoute');
    },
  );
}
