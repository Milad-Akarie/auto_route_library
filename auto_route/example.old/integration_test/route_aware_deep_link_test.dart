import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/pages.dart';

// A page a deep link builds under its top page hears didPushNext.
// Reproduces https://github.com/flutter/flutter/issues/70272 in auto_route.
// Headless test: auto_route/test/nested_route_aware_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: open the app on /second, which stacks SecondRoute on HomeRoute;
  // both pages have AutoRouteAwareStateMixin. Go back.
  // Should: HomeRoute hears didPush, then didPushNext, since SecondRoute
  // covers it; going back tells SecondRoute didPop and HomeRoute didPopNext.
  testWidgets(
    'a page built under a deep link hears didPushNext',
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
      routeAwareEvents.clear();
      await pumpRouterApp(
        tester,
        router,
        initialLink: '/second',
        navigatorObservers: () => [AutoRouteObserver()],
      );
      expectTopPage(router, 'SecondRoute');
      expect(
        routeAwareEvents,
        unorderedEquals([
          'HomeRoute.didPush',
          'HomeRoute.didPushNext',
          'SecondRoute.didPush',
        ]),
      );
      expect(
        routeAwareEvents.indexOf('HomeRoute.didPush'),
        lessThan(routeAwareEvents.indexOf('HomeRoute.didPushNext')),
      );

      routeAwareEvents.clear();
      await systemBack(tester);
      expectTopPage(router, 'HomeRoute');
      expect(routeAwareEvents, ['SecondRoute.didPop', 'HomeRoute.didPopNext']);
    },
  );
}
