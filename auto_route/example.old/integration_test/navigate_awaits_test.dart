import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/pages.dart';

// navigate() awaits the route it opens.
// https://github.com/Milad-Akarie/auto_route_library/issues/2154
// Headless test: auto_route/test/simple_router/router_widget_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: navigate to SecondRoute and await it, then pop SecondRoute with 'done'.
  // Should: the navigate() future stays open while SecondRoute shows, then
  // completes with 'done'.
  testWidgets(
    'navigate() completes with the result the opened page is popped with',
    (tester) async {
      final router = buildSimpleRouter();
      await pumpRouterApp(tester, router);
      var completed = false;
      Object? result;
      unawaited(
        router.navigate(const SecondRoute()).then((value) {
          completed = true;
          result = value;
        }),
      );
      await tester.pumpAndSettle();
      expectCurrentPage(router, SecondRoute.name);
      expect(
        completed,
        isFalse,
        reason: 'navigate() completed before the page was popped',
      );

      router.pop('done');
      await tester.pumpAndSettle();
      expect(completed, isTrue);
      expect(result, 'done');
    },
  );
}
