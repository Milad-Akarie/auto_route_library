import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/pages.dart';

// A page in a tab hears a bottom sheet declared at the root open and close.
// Guards https://github.com/Milad-Akarie/auto_route_library/issues/2306
// Headless test: auto_route/test/nested_route_aware_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('root bottom sheet aware', () {
    // Steps: AppRoute hosts tabs [DashboardRoute, SettingsRoute]; SettingsRoute
    // hosts a nested router showing SomethingRoute, a page with
    // AutoRouteAwareStateMixin. Open the settings tab, push BottomSheetRoute on
    // the root router, then go back.
    // Should: SomethingRoute gets didPushNext, then didPopNext.
    testWidgets('a page in a tab hears a root bottom sheet open and close', (
      tester,
    ) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: PageInfo(
              'AppRoute',
              builder: (_) => const AutoTabsRouter(
                routes: [
                  NamedRoute('DashboardRoute'),
                  NamedRoute('SettingsRoute'),
                ],
              ),
            ),
            children: [
              AutoRoute(
                path: 'dashboard',
                page: PageInfo(
                  'DashboardRoute',
                  builder: (_) => const RouteAwarePage(),
                ),
              ),
              AutoRoute(
                path: 'settings',
                page: PageInfo(
                  'SettingsRoute',
                  builder: (_) => const AutoRouter(),
                ),
                children: [
                  AutoRoute(
                    path: '',
                    page: PageInfo(
                      'SomethingRoute',
                      builder: (_) => const RouteAwarePage(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          CustomRoute(
            path: '/bottom-sheet',
            page: PageInfo(
              'BottomSheetRoute',
              builder: (_) => const Text('BottomSheetRoute'),
            ),
            customRouteBuilder: <T>(context, child, page) =>
                ModalBottomSheetRoute<T>(
                  settings: page,
                  isScrollControlled: true,
                  builder: (_) => child,
                ),
          ),
        ],
      );
      await pumpRouterApp(
        tester,
        router,
        navigatorObservers: () => [AutoRouteObserver()],
      );
      router.innerRouterOf<TabsRouter>('AppRoute')!.setActiveIndex(1);
      await tester.pumpAndSettle();
      expectTopPage(router, 'SomethingRoute');

      routeAwareEvents.clear();
      unawaited(router.root.push(const NamedRoute('BottomSheetRoute')));
      await tester.pumpAndSettle();
      expect(find.text('BottomSheetRoute'), findsOneWidget);
      expect(routeAwareEvents, ['SomethingRoute.didPushNext']);

      routeAwareEvents.clear();
      await systemBack(tester);
      expect(find.text('BottomSheetRoute'), findsNothing);
      expect(routeAwareEvents, ['SomethingRoute.didPopNext']);
    });
  });
}
