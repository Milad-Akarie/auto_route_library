import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A replaceAll() rejected by a guard leaves the stack as it was.
// https://github.com/Milad-Akarie/auto_route_library/issues/2299
// Headless test: auto_route/test/guards/replace_all_rejected_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Widget page(String name) => Scaffold(body: SafeArea(child: Text(name)));

  RootStackRouter buildRouter() => .build(
    routes: [
      NamedRouteDef(
        name: 'InitialRoute',
        path: '/',
        builder: (_, _) => page('InitialRoute'),
      ),
      NamedRouteDef(
        name: 'FooRoute',
        path: '/foo',
        builder: (_, _) => page('FooRoute'),
      ),
      NamedRouteDef(
        name: 'LoginRoute',
        path: '/login',
        builder: (_, data) => Scaffold(
          body: SafeArea(
            child: TextButton(
              onPressed: data.args! as VoidCallback,
              child: const Text('Cancel login'),
            ),
          ),
        ),
      ),
      NamedRouteDef(
        name: 'ProtectedRoute',
        path: '/protected',
        guards: [
          AutoRouteGuard.simple(
            (resolver, _) => resolver.redirectUntil(
              NamedRoute('LoginRoute', args: () => resolver.reject()),
            ),
          ),
        ],
        builder: (_, _) => page('ProtectedRoute'),
      ),
      NamedRouteDef(
        name: 'ForbiddenRoute',
        path: '/forbidden',
        guards: [AutoRouteGuardCallback((resolver, _) => resolver.reject())],
        builder: (_, _) => page('ForbiddenRoute'),
      ),
    ],
  );

  // Steps, the reporter's: push FooRoute, then replaceAll([ForbiddenRoute()]),
  // whose guard calls resolver.reject().
  // Should: the stack is still [InitialRoute, FooRoute], on screen and in the
  // url.
  testWidgets('A replaceAll rejected by a guard keeps the stack (#2299)', (
    tester,
  ) async {
    final router = buildRouter();
    await pumpRouterAppWithConfig(tester, router);
    unawaited(router.push(const NamedRoute('FooRoute')));
    await tester.pumpAndSettle();

    unawaited(router.replaceAll([const NamedRoute('ForbiddenRoute')]));
    await tester.pumpAndSettle();

    expect(router.stack.map((e) => e.routeData.name), [
      'InitialRoute',
      'FooRoute',
    ]);
    expectTopPage(router, 'FooRoute');
    await expectBrowserUrl('/foo');
  });

  // Steps: push FooRoute, replaceAll([ProtectedRoute()]), whose guard
  // redirects to LoginRoute, then tap 'Cancel login', which calls reject().
  // Should: the stack is [InitialRoute, FooRoute] again.
  testWidgets(
    'Canceling the redirect of a replaceAll restores the stack (#2299)',
    (tester) async {
      final router = buildRouter();
      await pumpRouterAppWithConfig(tester, router);
      unawaited(router.push(const NamedRoute('FooRoute')));
      await tester.pumpAndSettle();

      unawaited(router.replaceAll([const NamedRoute('ProtectedRoute')]));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel login'));
      await tester.pumpAndSettle();

      expect(router.stack.map((e) => e.routeData.name), [
        'InitialRoute',
        'FooRoute',
      ]);
      expectTopPage(router, 'FooRoute');
      await expectBrowserUrl('/foo');
    },
  );
}
