import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/pages.dart';

// A page in a nested router hears didPop when its host route is popped.
// Regression of https://github.com/Milad-Akarie/auto_route_library/issues/1863
// Headless test: auto_route/test/nested_route_aware_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: HomeRoute, then push HostRoute, which hosts a nested router
  // showing NestedRoute; both pages have AutoRouteAwareStateMixin. Go back.
  // Should: NestedRoute gets didPop, then HomeRoute gets didPopNext.
  testWidgets('a page in a nested router hears didPop when its host route is popped', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('HomeRoute', builder: (_) => const RouteAwarePage()),
        ),
        AutoRoute(
          path: '/host',
          page: PageInfo('HostRoute', builder: (_) => const AutoRouter()),
          children: [
            AutoRoute(
              path: '',
              page: PageInfo('NestedRoute', builder: (_) => const RouteAwarePage()),
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router, navigatorObservers: () => [AutoRouteObserver()]);
    unawaited(router.push(const NamedRoute('HostRoute')));
    await tester.pumpAndSettle();
    expectTopPage(router, 'NestedRoute');

    routeAwareEvents.clear();
    await systemBack(tester);
    expectTopPage(router, 'HomeRoute');
    expect(routeAwareEvents, ['NestedRoute.didPop', 'HomeRoute.didPopNext']);
  });
}
