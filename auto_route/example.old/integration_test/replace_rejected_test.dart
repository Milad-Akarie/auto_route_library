import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A replace() rejected by the new route's guard leaves the stack as it was.
// https://github.com/Milad-Akarie/auto_route_library/issues/2046
// Headless test: auto_route/test/guards/replace_rejected_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('replace rejected', () {
    Widget page(String name) => Scaffold(body: SafeArea(child: Text(name)));

    RootStackRouter buildRouter() => .build(
      routes: [
        NamedRouteDef(
          name: 'HomeRoute',
          path: '/',
          builder: (_, _) => page('HomeRoute'),
        ),
        NamedRouteDef(
          name: 'DetailsRoute',
          path: '/details',
          builder: (_, _) => page('DetailsRoute'),
        ),
        NamedRouteDef(
          name: 'LoginRoute',
          path: '/login',
          builder: (_, _) => page('LoginRoute'),
        ),
        NamedRouteDef(
          name: 'ProtectedRoute',
          path: '/protected',
          guards: [
            AutoRouteGuard.simple(
              (resolver, _) =>
                  resolver.redirectUntil(const NamedRoute('LoginRoute')),
            ),
          ],
          builder: (_, _) => page('ProtectedRoute'),
        ),
        NamedRouteDef(
          name: 'ForbiddenRoute',
          path: '/forbidden',
          guards: [AutoRouteGuard.simple((resolver, _) => resolver.reject())],
          builder: (_, _) => page('ForbiddenRoute'),
        ),
      ],
    );

    // Steps: push DetailsRoute, then replace it with ForbiddenRoute, whose
    // guard rejects the navigation.
    // Should: the stack is still [HomeRoute, DetailsRoute], on screen and in
    // the url.
    testWidgets(
      'A replace rejected by a guard keeps the page it would replace (#2046)',
      (tester) async {
        final router = buildRouter();
        await pumpRouterAppWithConfig(tester, router);
        unawaited(router.push(const NamedRoute('DetailsRoute')));
        await tester.pumpAndSettle();

        unawaited(router.replace(const NamedRoute('ForbiddenRoute')));
        await tester.pumpAndSettle();

        expect(router.stack.map((e) => e.routeData.name), [
          'HomeRoute',
          'DetailsRoute',
        ]);
        expectTopPage(router, 'DetailsRoute');
        await expectBrowserUrl('/details');
      },
    );

    // Steps: push DetailsRoute, replace it with ProtectedRoute, whose guard
    // redirects to LoginRoute, then go back from LoginRoute.
    // Should: LoginRoute opens over DetailsRoute, and going back rejects the
    // replace and shows DetailsRoute again.
    testWidgets(
      'Going back from the redirect of a replace keeps the page it would '
      'replace '
      '(#2046)',
      (tester) async {
        final router = buildRouter();
        await pumpRouterAppWithConfig(tester, router);
        unawaited(router.push(const NamedRoute('DetailsRoute')));
        await tester.pumpAndSettle();

        unawaited(router.replace(const NamedRoute('ProtectedRoute')));
        await tester.pumpAndSettle();
        expect(router.stack.map((e) => e.routeData.name), [
          'HomeRoute',
          'DetailsRoute',
          'LoginRoute',
        ]);

        await systemBack(tester);
        expect(router.stack.map((e) => e.routeData.name), [
          'HomeRoute',
          'DetailsRoute',
        ]);
        expectTopPage(router, 'DetailsRoute');
        await expectBrowserUrl('/details');
      },
    );
  });
}
