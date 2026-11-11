import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../reevaluatable_router/auth_state.dart';
import '../router_test_utils.dart';

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));

// Reproduction for https://github.com/Milad-Akarie/auto_route_library/issues/2265
// This is the first of the two problems in the report; the second is a
// question about how to build a feature.
// The report has no code, so the setup is assumed. A guarded dashboard page
// at the root holds tabs with homeIndex 0: Overview, then Settings. The guard
// sends a logged-out user to the login page. The router reevaluates when the
// auth state changes. The login button logs in and replaces the stack with the
// dashboard.
// Steps: start logged in on Overview, log out, then log in again.
// Should: the dashboard shows its Overview tab.
// Reported: it shows Settings, the last of the tabs.
// The reporter's own cause: the tab shown is picked from the dashboard's
// pending children, the tabs its match carried through the guard's redirect,
// and the last one wins. So the second test sends the user through the
// redirect with a pending child: the app starts logged out on the link
// '/settings', so the guard redirects to the login page and holds Settings
// pending; logging in opens it. After logging out, a new navigation to the
// dashboard goes through the guard again, and that login must open the home
// tab, not the Settings child held pending the first time.
// Not tested: a navigation that names both tabs as children,
// DashboardRoute(children: [Overview, Settings]), opens Settings after the
// redirect, as the last child it names. That is the caller's own choice.
void main() {
  testWidgets('Logging in again opens the home tab of the dashboard (#2265)', (
    tester,
  ) async {
    final auth = AuthState()..isLoggedIn = true;
    addTearDown(auth.dispose);
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('LoginRoute'), path: '/login'),
        AutoRoute(
          page: PageInfo(
            'DashboardRoute',
            builder: (_) => const AutoTabsRouter(homeIndex: 0),
          ),
          path: '/',
          initial: true,
          guards: [
            AutoRouteGuard.redirect(
              (resolver) =>
                  auth.isLoggedIn ? null : const NamedRoute('LoginRoute'),
            ),
          ],
          children: [
            AutoRoute(page: _page('OverviewRoute'), path: 'overview'),
            AutoRoute(page: _page('SettingsRoute'), path: 'settings'),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router, reevaluationNotifier: auth);
    expect(find.text('OverviewRoute'), findsOneWidget);

    auth.isLoggedIn = false;
    await tester.pumpAndSettle();
    expect(find.text('LoginRoute'), findsOneWidget);

    auth.isLoggedIn = true;
    unawaited(router.replaceAll([const NamedRoute('DashboardRoute')]));
    await tester.pumpAndSettle();

    expect(router.urlState.url, '/overview');
    expect(find.text('SettingsRoute'), findsNothing);
  });

  testWidgets('Logging in through the guard redirect again opens the home tab '
      'of the dashboard (#2265)', (tester) async {
    final auth = AuthState();
    addTearDown(auth.dispose);
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'LoginRoute',
          path: '/login',
          builder: (_, data) => Scaffold(
            body: TextButton(
              onPressed: () {
                auth.isLoggedIn = true;
                (data.args! as VoidCallback)();
              },
              child: const Text('LoginRoute'),
            ),
          ),
        ),
        AutoRoute(
          page: PageInfo(
            'DashboardRoute',
            builder: (_) => const AutoTabsRouter(homeIndex: 0),
          ),
          path: '/',
          initial: true,
          guards: [
            AutoRouteGuard.simple((resolver, _) {
              if (auth.isLoggedIn) {
                resolver.next();
              } else {
                unawaited(
                  resolver.redirectUntil(
                    NamedRoute('LoginRoute', args: resolver.next),
                  ),
                );
              }
            }),
          ],
          children: [
            AutoRoute(page: _page('OverviewRoute'), path: 'overview'),
            AutoRoute(page: _page('SettingsRoute'), path: 'settings'),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router, initialLink: '/settings');
    expect(router.urlState.url, '/login', reason: 'sent to the login');

    await tester.tap(find.text('LoginRoute'));
    await tester.pumpAndSettle();
    expect(router.urlState.url, '/settings', reason: 'the pending child');

    auth.isLoggedIn = false;
    unawaited(router.replaceAll([const NamedRoute('DashboardRoute')]));
    await tester.pumpAndSettle();
    expect(find.text('LoginRoute'), findsOneWidget);

    await tester.tap(find.text('LoginRoute'));
    await tester.pumpAndSettle();

    expect(router.urlState.url, '/overview');
    expect(find.text('SettingsRoute'), findsNothing);
  });
}
