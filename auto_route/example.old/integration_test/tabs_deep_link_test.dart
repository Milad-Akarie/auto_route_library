import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A deep link into a tab opens the nested page and keeps it.
// https://github.com/Milad-Akarie/auto_route_library/issues/2171
// Headless test: auto_route/test/web/tabs_deep_link_web_test.dart
void main() {
  group('tabs deep link', () {
    final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    tearDown(binding.platformDispatcher.clearDefaultRouteNameTestValue);

    // Steps: open the app from the platform's link '/profile/account', inside
    // the profile tab of an AutoTabsRouter whose route has a guard, then
    // reevaluate the guard.
    // Should: the account page stays, and the url, and on web the address
    // bar, keeps '/profile/account', not '/profile'.
    testWidgets('A deep link into a tab opens the nested page and keeps it', (
      tester,
    ) async {
      final reevaluate = ValueNotifier(0);
      binding.platformDispatcher.defaultRouteNameTestValue = '/profile/account';
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(page: _page('LoginRoute'), path: '/login'),
          AutoRoute(
            page: _tabsPage,
            path: '/',
            initial: true,
            guards: const [_LateGuard()],
            children: [
              AutoRoute(page: _page('HomeRoute'), path: 'home'),
              AutoRoute(
                page: _shellPage('ProfileRoute'),
                path: 'profile',
                children: [
                  AutoRoute(page: _page('ProfileContentRoute'), path: ''),
                  AutoRoute(
                    page: _shellPage('AccountRoute'),
                    path: 'account',
                    children: [
                      AutoRoute(page: _page('AccountContentRoute'), path: ''),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      await pumpRouterConfigApp(
        tester,
        router.config(reevaluateListenable: reevaluate),
      );
      expect(find.text('AccountContentRoute'), findsOneWidget);
      await expectBrowserUrl('/profile/account');

      reevaluate.value++;
      await tester.pumpAndSettle();
      expect(find.text('AccountContentRoute'), findsOneWidget);
      expect(router.urlState.url, '/profile/account');
      await expectBrowserUrl('/profile/account');
    });
  });
}

PageInfo _page(String name) => .new(name, builder: (_) => Text(name));

PageInfo _shellPage(String name) =>
    .new(name, builder: (_) => const AutoRouter());

final _tabsPage = PageInfo(
  'AuthenticatedAppRoute',
  builder: (_) => AutoTabsRouter(
    routes: const [PageRouteInfo('HomeRoute'), PageRouteInfo('ProfileRoute')],
    builder: (_, child) => child,
  ),
);

class _LateGuard extends AutoRouteGuard {
  const new();

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    unawaited(
      Future.delayed(
        const Duration(milliseconds: 20),
        () => resolver.next(),
      ),
    );
  }
}
