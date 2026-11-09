import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';
import 'auth_state.dart';

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));

// Reproduction for https://github.com/Milad-Akarie/auto_route_library/issues/2151
// Setup, as reported (auto_route 9.3, Flutter 3.27): reevaluateListenable is
// the auth provider. With the guarded page at the top level of the router,
// logging out asks the guard again. With a wrapper page whose children are
// LoginRoute and the guarded GuardedRoute (initial), it did not. The guard
// sends a logged-out user to LoginRoute.
// Steps: log in, show GuardedRoute inside the wrapper, log out.
// Should: the guard is asked again and LoginRoute shows, in both layouts.
void main() {
  for (final nested in [false, true]) {
    testWidgets('Logging out reevaluates the guard '
        '(${nested ? 'inside a wrapper page' : 'at the top level'}, #2151)', (
      tester,
    ) async {
      final auth = AuthState()..isLoggedIn = true;
      addTearDown(auth.dispose);
      var asked = 0;
      final login = _page('LoginRoute');
      final guarded = AutoRoute(
        page: _page('GuardedRoute'),
        path: nested ? 'guarded' : '/',
        initial: true,
        guards: [
          AutoRouteGuard.redirect((resolver) {
            asked++;
            return auth.isLoggedIn ? null : const NamedRoute('LoginRoute');
          }),
        ],
      );
      final router = RootStackRouter.build(
        routes: nested
            ? [
                AutoRoute(
                  page: PageInfo(
                    'WrapperRoute',
                    builder: (_) => const AutoRouter(),
                  ),
                  path: '/',
                  initial: true,
                  children: [
                    AutoRoute(page: login, path: 'login'),
                    guarded,
                  ],
                ),
              ]
            : [AutoRoute(page: login, path: '/login'), guarded],
      );
      await pumpRouterApp(tester, router, reevaluationNotifier: auth);
      expect(find.text('GuardedRoute'), findsOneWidget);
      final askedBeforeLogout = asked;

      auth.isLoggedIn = false;
      await tester.pumpAndSettle();

      expect(asked, greaterThan(askedBeforeLogout));
      expect(find.text('LoginRoute'), findsOneWidget);
      expect(find.text('GuardedRoute'), findsNothing);
    });
  }
}
