import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/pages.dart';

// AutoRouteAwareStateMixin hears push and pop in a plain stack.
// Guards https://github.com/Milad-Akarie/auto_route_library/issues/2315
// Headless test: auto_route/test/auto_route_observer_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: no tabs or nested routers; the app hands an AutoRouteObserver
  // through config(), and BookListRoute uses AutoRouteAwareStateMixin. Push
  // BookDetailsRoute, then go back.
  // Should: BookListRoute gets didPushNext, then didPopNext.
  testWidgets('AutoRouteAwareStateMixin hears push and pop with the observer given to config()', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('BookListRoute', builder: (_) => const RouteAwarePage()),
        ),
        AutoRoute(
          path: '/details',
          page: PageInfo('BookDetailsRoute', builder: (_) => const TestPage()),
        ),
      ],
    );
    await pumpRouterConfigApp(
      tester,
      router.config(
        navigatorObservers: () => [AutoRouteObserver()],
        deepLinkBuilder: (link) => link.initial ? const DeepLink.path('/') : link,
      ),
    );
    expectTopPage(router, 'BookListRoute');

    routeAwareEvents.clear();
    unawaited(router.push(const NamedRoute('BookDetailsRoute')));
    await tester.pumpAndSettle();
    expectTopPage(router, 'BookDetailsRoute');
    expect(routeAwareEvents, ['BookListRoute.didPushNext']);

    routeAwareEvents.clear();
    await systemBack(tester);
    expectTopPage(router, 'BookListRoute');
    expect(routeAwareEvents, ['BookListRoute.didPopNext']);
  });
}
