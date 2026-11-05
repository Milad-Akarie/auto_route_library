import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// #582: an app that swapped between two RootStackRouters when the user
// signed in went blank. The reporter's app: one MaterialApp.router whose
// delegate and parser come from a signed-out router ('/login', '/signup' and
// '*' redirecting to '/login') or a signed-in router ('/' and '*' redirecting
// to '/'), picked in a builder that rebuilds when sign-in flips.
// Steps: open the app signed out, sign in, then sign out again.
// Should: each flip shows the other router's page, not a blank screen.
void main() {
  Widget page(String name) => Text(name);

  RootStackRouter signedOutRouter() => .build(
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

  RootStackRouter signedInRouter() => .build(
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

  // The url the Router last reported to the platform.
  String reportedUrl(WidgetTester tester) =>
      Router.of(tester.element(find.byType(Navigator).first))
          .routeInformationProvider!
          .value
          .uri
          .toString();

  testWidgets('Swapping the router on sign-in shows the new router', (
    tester,
  ) async {
    final signedOut = signedOutRouter();
    final signedIn = signedInRouter();
    addTearDown(signedOut.dispose);
    addTearDown(signedIn.dispose);
    final isSignedIn = ValueNotifier(false);
    addTearDown(isSignedIn.dispose);
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
    final atStart = (
      find.text('login').evaluate().length,
      signedOut.currentUrl,
    );

    isSignedIn.value = true;
    await tester.pumpAndSettle();
    final afterSignIn = (
      tester.takeException(),
      find.text('home').evaluate().length,
      find.text('login').evaluate().length,
      signedIn.currentUrl,
      reportedUrl(tester),
    );

    isSignedIn.value = false;
    await tester.pumpAndSettle();
    expect(
      (
        atStart,
        afterSignIn,
        tester.takeException(),
        find.text('login').evaluate().length,
        find.text('home').evaluate().length,
        reportedUrl(tester),
      ),
      ((1, '/login'), (null, 1, 0, '/', '/'), null, 1, 0, '/login'),
    );
  });
}
