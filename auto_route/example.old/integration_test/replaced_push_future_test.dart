import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/pages.dart';

// The push future completes when the route that replaced the pushed one pops.
// https://github.com/Milad-Akarie/auto_route_library/issues/2251
// Headless test: auto_route/test/simple_router/router_widget_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RootStackRouter router;
  setUp(() => router = buildSimpleRouter());

  // Steps: push SecondRoute and await it, replace it with
  // ThirdRoute, then pop ThirdRoute.
  // Should: the future of the first push completes once ThirdRoute is popped.
  testWidgets(
    'Popping a route that replaced the pushed one completes the first push '
    'future (#2251)',
    (tester) async {
      await pumpRouterApp(tester, router);
      var isCompleted = false;
      unawaited(
        router
            .push<String>(const SecondRoute())
            .then((_) => isCompleted = true),
      );
      await tester.pumpAndSettle();

      unawaited(router.replace(const ThirdRoute()));
      await tester.pumpAndSettle();
      expectCurrentPage(router, ThirdRoute.name);

      router.pop();
      await tester.pumpAndSettle();

      expectCurrentPage(router, FirstRoute.name);
      expect(isCompleted, isTrue);
    },
  );
}
