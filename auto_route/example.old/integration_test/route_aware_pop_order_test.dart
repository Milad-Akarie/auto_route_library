import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/pages.dart';

// Going back tells the page that leaves didPop before the page under it hears
// didPopNext. Reproduces https://github.com/flutter/flutter/issues/26902 in
// auto_route.
// Headless test: auto_route/test/nested_route_aware_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: HomeRoute, then push SecondRoute; both pages have
  // AutoRouteAwareStateMixin. Go back.
  // Should: SecondRoute gets didPop, then HomeRoute gets didPopNext.
  testWidgets(
    'going back tells the page that leaves before the page that shows again',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: PageInfo('HomeRoute', builder: (_) => const RouteAwarePage()),
          ),
          AutoRoute(
            path: '/second',
            page: PageInfo(
              'SecondRoute',
              builder: (_) => const RouteAwarePage(),
            ),
          ),
        ],
      );
      await pumpRouterApp(
        tester,
        router,
        navigatorObservers: () => [AutoRouteObserver()],
      );
      unawaited(router.push(const NamedRoute('SecondRoute')));
      await tester.pumpAndSettle();
      expectTopPage(router, 'SecondRoute');

      routeAwareEvents.clear();
      await systemBack(tester);
      expectTopPage(router, 'HomeRoute');
      expect(routeAwareEvents, ['SecondRoute.didPop', 'HomeRoute.didPopNext']);
    },
  );
}
