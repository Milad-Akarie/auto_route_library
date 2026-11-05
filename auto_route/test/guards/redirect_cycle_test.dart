import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

class _AppRouter extends RootStackRouter {
  new({required this.routes, this.guards = const []});

  @override
  final List<AutoRouteGuard> guards;

  @override
  final List<AutoRoute> routes;
}

void main() {
  late int guardCalls;
  setUp(() => guardCalls = 0);

  Widget page(String name) => Scaffold(body: Center(child: Text(name)));

  // Stands in for the guard's own logic; past this many calls it stops
  // redirecting, so the test still ends where the loop used to run forever.
  bool loopedTooLong() => ++guardCalls > 100;

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

  // https://github.com/flutter/flutter/issues/118061
  // A go_router redirect that always sends the user somewhere, including from
  // the page it sends them to, looped until the stack overflowed. In
  // auto_route, AutoRouteGuard.redirect() in RootStackRouter.guards does the
  // same: it runs for LoginRoute too and pushes LoginRoute again. Steps: start
  // the app at HomeRoute with that global guard.
  // The loop must stop with an error that names the routes.
  testWidgets(
    'A global AutoRouteGuard.redirect that redirects its own target reports the loop (flutter/flutter#118061)',
    (tester) async {
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
        guards: [
          AutoRouteGuard.redirect(
            (_) => loopedTooLong() ? null : const NamedRoute('LoginRoute'),
          ),
        ],
      );

      final errors = await collectErrors(
        tester,
        () => pumpRouterConfigApp(tester, router.config()),
      );

      expect(errors, hasLength(1));
      expect(errors.singleOrNull?.exception.toString(), contains('LoginRoute'));
      expect(guardCalls, lessThan(100));
    },
  );

  // https://github.com/flutter/flutter/issues/118061
  // Two route guards that send the user to each other's route. Steps: start at
  // HomeRoute, push ARoute, whose guard calls redirectUntil(BRoute), whose
  // guard calls redirectUntil(ARoute).
  // The loop must stop with an error that names the routes.
  testWidgets(
    'Two guards whose redirectUntil sends to each other report the loop (flutter/flutter#118061)',
    (tester) async {
      final aGuard = AutoRouteGuard.simple((resolver, _) {
        if (loopedTooLong()) return resolver.next();
        unawaited(resolver.redirectUntil(const NamedRoute('BRoute')));
      });
      final bGuard = AutoRouteGuard.simple((resolver, _) {
        if (loopedTooLong()) return resolver.next();
        unawaited(resolver.redirectUntil(const NamedRoute('ARoute')));
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
            guards: [aGuard],
            builder: (_, _) => page('ARoute'),
          ),
          NamedRouteDef(
            name: 'BRoute',
            path: '/b',
            guards: [bGuard],
            builder: (_, _) => page('BRoute'),
          ),
        ],
      );
      await pumpRouterConfigApp(tester, router.config());

      final errors = await collectErrors(tester, () async {
        unawaited(router.push(const NamedRoute('ARoute')));
      });

      expect(errors, hasLength(1));
      expect(
        errors.singleOrNull?.exception.toString(),
        allOf(contains('ARoute'), contains('BRoute')),
      );
      expect(guardCalls, lessThan(100));
    },
  );

  // https://github.com/flutter/flutter/issues/118061
  // The same loop through AutoRouteGuard.redirectPath(). Steps: start the app
  // at HomeRoute with a global guard that always redirects to /login.
  testWidgets(
    'A global AutoRouteGuard.redirectPath that redirects its own target reports the loop (flutter/flutter#118061)',
    (tester) async {
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
        guards: [
          AutoRouteGuard.redirectPath((_) => loopedTooLong() ? null : '/login'),
        ],
      );

      final errors = await collectErrors(
        tester,
        () => pumpRouterConfigApp(tester, router.config()),
      );

      expect(errors, hasLength(1));
      expect(
        errors.singleOrNull?.exception.toString(),
        contains('A guard redirected LoginRoute to itself.'),
      );
      expect(guardCalls, 2);
    },
  );

  // A guard that sends a route to the same route with a child is no loop:
  // the second time the guard sees the child and lets it through.
  testWidgets(
    'A guard redirecting a route to its own default child is not a loop (flutter/flutter#118061)',
    (tester) async {
      final router = _AppRouter(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            builder: (_, _) => const AutoRouter(),
            guards: [
              AutoRouteGuard.redirectPath(
                (resolver) => resolver.route.hasChildren || loopedTooLong()
                    ? null
                    : '/feed',
              ),
            ],
            children: [
              NamedRouteDef(
                name: 'FeedRoute',
                path: 'feed',
                builder: (_, _) => page('FeedRoute'),
              ),
            ],
          ),
        ],
      );

      final errors = await collectErrors(
        tester,
        () => pumpRouterConfigApp(tester, router.config()),
      );

      expect(errors, isEmpty);
      expectTopPage(router, 'FeedRoute');
    },
  );

  // A re-check starts over: LoginRoute, opened by a redirect from HomeRoute,
  // sends the user back to HomeRoute once they are logged in.
  testWidgets(
    'A re-checked route redirecting back to the route that redirected to it is not a loop (flutter/flutter#118061)',
    (tester) async {
      final auth = ValueNotifier(false);
      addTearDown(auth.dispose);
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
        guards: [
          AutoRouteGuard.redirect((resolver) {
            if (loopedTooLong()) return null;
            final onLogin = resolver.routeName == 'LoginRoute';
            if (auth.value)
              return onLogin ? const NamedRoute('HomeRoute') : null;
            return onLogin ? null : const NamedRoute('LoginRoute');
          }),
        ],
      );

      final errors = await collectErrors(tester, () async {
        await pumpRouterConfigApp(
          tester,
          router.config(reevaluateListenable: auth),
        );
        expectTopPage(router, 'LoginRoute');
        auth.value = true;
      });

      expect(errors, isEmpty);
      expectTopPage(router, 'HomeRoute');
    },
  );
}
