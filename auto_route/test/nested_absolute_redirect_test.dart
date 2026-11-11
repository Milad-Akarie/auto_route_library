import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// #393: a RedirectRoute among a parent's children whose redirectTo is an
// absolute path, '/auth', to a top-level route, showed the not-found page.
// The reporter's routes: home at '/' with children '' and 'd' (redirecting
// to '/auth'), then '/auth' and a '/*' not-found route at the top. Open '/d'.
// Should: the auth page shows at '/auth'.
void main() {
  Widget page(String name) => Text(name);

  testWidgets('A nested redirect to an absolute path opens the top route', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'HomeRoute',
          path: '/',
          initial: true,
          builder: (_, _) => const AutoRouter(),
          children: [
            NamedRouteDef(
              name: 'PublicRoute',
              path: '',
              builder: (_, _) => page('public'),
            ),
            RedirectRoute(path: 'd', redirectTo: '/auth'),
          ],
        ),
        NamedRouteDef(
          name: 'AuthRoute',
          path: '/auth',
          builder: (_, _) => page('auth'),
        ),
        NamedRouteDef(
          name: 'NotFoundRoute',
          path: '*',
          builder: (_, _) => page('not found'),
        ),
      ],
    );
    await pumpRouterApp(tester, router, initialLink: '/d');
    expect(find.text('auth'), findsOneWidget);
    expect(router.currentUrl, '/auth');
  });
  // #393, a loop through levels: '/d' sends to '/auth', which sends back to
  // '/d'. Should: the loop is reported, naming each step.
  test('A loop through a nested absolute redirect is reported', () {
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'HomeRoute',
          path: '/',
          builder: (_, _) => const AutoRouter(),
          children: [RedirectRoute(path: 'd', redirectTo: '/auth')],
        ),
        RedirectRoute(path: '/auth', redirectTo: '/d'),
      ],
    );
    addTearDown(router.dispose);
    expect(
      () => router.matcher.match('/d'),
      throwsA(
        isA<FlutterError>().having(
          (e) => e.message,
          'message',
          startsWith('Redirect loop detected: d -> /auth -> d'),
        ),
      ),
    );
  });
}
