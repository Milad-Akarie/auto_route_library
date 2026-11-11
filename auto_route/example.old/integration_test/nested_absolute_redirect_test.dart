import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A RedirectRoute among a parent's children whose redirectTo is an absolute
// path opens the top-level route it names.
// https://github.com/Milad-Akarie/auto_route_library/issues/393
// Headless test: auto_route/test/nested_absolute_redirect_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('nested absolute redirect', () {
    Widget page(String name) => Scaffold(body: Text(name));

    // Steps: home at '/' holds '' and 'd', which redirects to '/auth'; '/auth'
    // and a '*' not-found route are at the top. Open the app at '/d'.
    // Should: the auth page shows at '/auth', not the not-found page.
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
      addTearDown(router.dispose);
      await pumpRouterApp(tester, router, initialLink: '/d');
      expect(find.text('auth'), findsOneWidget);
      expect(router.currentUrl, '/auth');
      await expectBrowserUrl('/auth');
    });
  });
}
