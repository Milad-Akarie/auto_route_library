import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/pages.dart';

// navigate() to an open host route updates its nested router right away.
// Regression of https://github.com/Milad-Akarie/auto_route_library/issues/2154
// Headless test: auto_route/test/nested_router/router_widget_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('navigate nested update', () {
    // Steps: navigate to SecondHostRoute, push SecondNested3Route in its nested
    // router, then navigate to SecondHostRoute with children
    // [SecondNested1Route].
    // Should: SecondNested1Route shows right away, not once the host is popped.
    testWidgets('navigate() to an open host route updates its nested router', (
      tester,
    ) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(path: '/', page: FirstRoute.page),
          AutoRoute(
            path: '/second',
            page: SecondHostRoute.page,
            children: [
              AutoRoute(path: '', page: SecondNested1Route.page),
              AutoRoute(path: 'nested3', page: SecondNested3Route.page),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      unawaited(router.navigate(const SecondHostRoute()));
      await tester.pumpAndSettle();
      unawaited(
        router
            .innerRouterOf<StackRouter>(SecondHostRoute.name)!
            .push(const SecondNested3Route()),
      );
      await tester.pumpAndSettle();
      expectTopPage(router, SecondNested3Route.name);

      unawaited(
        router.navigate(
          const SecondHostRoute(children: [SecondNested1Route()]),
        ),
      );
      await tester.pumpAndSettle();
      expectTopPage(router, SecondNested1Route.name);
    });
  });
}
