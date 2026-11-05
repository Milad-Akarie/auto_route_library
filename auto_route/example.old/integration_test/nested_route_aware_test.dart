import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/pages.dart';

// A page in a nested router hears a root route cover and uncover its host.
// Regression of https://github.com/Milad-Akarie/auto_route_library/issues/1954
// Headless test: auto_route/test/nested_route_aware_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: HostRoute hosts a nested router showing NestedRoute, a page with
  // AutoRouteAwareStateMixin. Push CoverRoute at the root, then go back.
  // Should: NestedRoute gets didPushNext, then didPopNext.
  testWidgets('a page in a nested router hears a root route cover and uncover its host', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('HostRoute', builder: (_) => const AutoRouter()),
          children: [
            AutoRoute(
              path: '',
              page: PageInfo('NestedRoute', builder: (_) => const RouteAwarePage()),
            ),
          ],
        ),
        AutoRoute(
          path: '/cover',
          page: PageInfo('CoverRoute', builder: (_) => const RouteAwarePage()),
        ),
      ],
    );
    await pumpRouterApp(tester, router, navigatorObservers: () => [AutoRouteObserver()]);
    expectTopPage(router, 'NestedRoute');

    routeAwareEvents.clear();
    unawaited(router.push(const NamedRoute('CoverRoute')));
    await tester.pumpAndSettle();
    expectTopPage(router, 'CoverRoute');
    expect(routeAwareEvents, ['NestedRoute.didPushNext', 'CoverRoute.didPush']);

    routeAwareEvents.clear();
    await systemBack(tester);
    expectTopPage(router, 'NestedRoute');
    expect(routeAwareEvents, ['CoverRoute.didPop', 'NestedRoute.didPopNext']);
  });
}
