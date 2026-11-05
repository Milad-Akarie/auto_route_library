import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// An app that swaps between two routers when the user signs in shows the new
// router's page, not a blank screen.
// https://github.com/Milad-Akarie/auto_route_library/issues/582
// Headless test: auto_route/test/simple_router/switch_routers_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('switch routers', () {
    Widget page(String name) => Scaffold(body: Text(name));

    // Steps: one MaterialApp.router takes its delegate and parser from a
    // signed-out router ('/login', '/signup', '*' to '/login') or a signed-in
    // router ('/', '*' to '/'). Open it signed out, sign in, sign out.
    // Should: home shows at '/' after signing in, login at '/login' after
    // signing out.
    testWidgets('Swapping the router on sign-in shows the new router', (
      tester,
    ) async {
      final signedOut = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'LoginRoute',
            path: '/login',
            initial: true,
            builder: (_, _) => page('login'),
          ),
          NamedRouteDef(
            name: 'SignupRoute',
            path: '/signup',
            builder: (_, _) => page('signup'),
          ),
          RedirectRoute(path: '*', redirectTo: '/login'),
        ],
      );
      final signedIn = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            initial: true,
            builder: (_, _) => page('home'),
          ),
          RedirectRoute(path: '*', redirectTo: '/'),
        ],
      );
      addTearDown(signedOut.dispose);
      addTearDown(signedIn.dispose);
      final isSignedIn = ValueNotifier(false);
      addTearDown(isSignedIn.dispose);
      tester.binding.handleAppLifecycleStateChanged(.resumed);
      await tester.pumpWidget(
        ValueListenableBuilder(
          valueListenable: isSignedIn,
          builder: (_, isSignedInNow, _) {
            final router = isSignedInNow ? signedIn : signedOut;
            return MaterialApp.router(
              routerDelegate: router.delegate(),
              routeInformationParser: router.defaultRouteParser(),
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      final loginsAtStart = find.text('login').evaluate().length;

      isSignedIn.value = true;
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
      expect(signedIn.currentUrl, '/');
      await expectBrowserUrl('/');

      isSignedIn.value = false;
      await tester.pumpAndSettle();
      expect((loginsAtStart, find.text('login').evaluate().length), (1, 1));
      await expectBrowserUrl('/login');
    });
  });
}
