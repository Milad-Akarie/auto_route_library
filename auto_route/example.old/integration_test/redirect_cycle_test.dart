import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// Guards that send the user on in a circle report the loop instead of
// recursing until the stack overflows or running forever.
// https://github.com/flutter/flutter/issues/118061
// Headless test: auto_route/test/guards/redirect_cycle_test.dart
class _AppRouter extends RootStackRouter {
  _AppRouter({this.guards = const [], required this.routes});

  @override
  final List<AutoRouteGuard> guards;

  @override
  final List<AutoRoute> routes;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Widget page(String name) => Scaffold(body: SafeArea(child: Text(name)));

  Future<List<FlutterErrorDetails>> collectErrors(
    WidgetTester tester,
    Future<void> Function() body,
  ) async {
    final reported = <FlutterErrorDetails>[];
    final onError = FlutterError.onError;
    FlutterError.onError = reported.add;
    addTearDown(() => FlutterError.onError = onError);
    await body();
    await tester.pumpAndSettle();
    FlutterError.onError = onError;
    return reported;
  }

  // Steps: open an app whose global AutoRouteGuard.redirect() always returns
  // LoginRoute, so it redirects LoginRoute to itself too.
  // Should: the guard runs twice, for HomeRoute and for LoginRoute, and the
  // second redirect reports an error that names LoginRoute.
  testWidgets(
    'A global AutoRouteGuard.redirect that redirects its own target reports '
    'the loop',
    (tester) async {
      var guardCalls = 0;
      final router = _AppRouter(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            builder: (_, _) => page('HomeRoute'),
          ),
          NamedRouteDef(
            name: 'LoginRoute',
            path: '/login',
            builder: (_, _) => page('LoginRoute'),
          ),
        ],
        // past a few calls the guard stops redirecting, so the test still ends
        // where the loop ran forever
        guards: [
          AutoRouteGuard.redirect(
            (_) => ++guardCalls > 100 ? null : const NamedRoute('LoginRoute'),
          ),
        ],
      );

      final errors = await collectErrors(
        tester,
        () => pumpRouterAppWithConfig(tester, router),
      );

      expect(errors, hasLength(1));
      expect(
        errors.single.exception.toString(),
        contains('A guard redirected LoginRoute to itself.'),
      );
      expect(guardCalls, 2);
    },
  );

  // Steps: open HomeRoute, then push ARoute, whose guard calls
  // redirectUntil(BRoute), whose guard calls redirectUntil(ARoute).
  // Should: an error names the loop, and HomeRoute stays on screen.
  testWidgets(
    'Two guards whose redirectUntil sends to each other report the loop',
    (tester) async {
      var guardCalls = 0;
      AutoRouteGuard redirectTo(String name) => .simple((resolver, _) {
        if (++guardCalls > 100) return resolver.next();
        unawaited(resolver.redirectUntil(NamedRoute(name)));
      });
      final router = _AppRouter(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            builder: (_, _) => page('HomeRoute'),
          ),
          NamedRouteDef(
            name: 'ARoute',
            path: '/a',
            guards: [redirectTo('BRoute')],
            builder: (_, _) => page('ARoute'),
          ),
          NamedRouteDef(
            name: 'BRoute',
            path: '/b',
            guards: [redirectTo('ARoute')],
            builder: (_, _) => page('BRoute'),
          ),
        ],
      );
      await pumpRouterAppWithConfig(tester, router);

      final errors = await collectErrors(tester, () async {
        unawaited(router.push(const NamedRoute('ARoute')));
      });

      expect(errors, hasLength(1));
      expect(
        errors.single.exception.toString(),
        contains('Guards redirected in a loop: ARoute → BRoute → ARoute.'),
      );
      expect(guardCalls, 2);
      expect(find.text('HomeRoute'), findsOneWidget);
    },
  );
}
