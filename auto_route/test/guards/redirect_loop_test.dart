import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

class _AppRouter extends RootStackRouter {
  _AppRouter({required this.guards, required this.routes});

  @override
  final List<AutoRouteGuard> guards;

  @override
  final List<AutoRoute> routes;
}

void main() {
  late int guardCalls;
  setUp(() => guardCalls = 0);

  Widget page(String name) => Scaffold(body: Center(child: Text(name)));

  final routes = [
    NamedRouteDef(name: 'HomeRoute', path: '/', meta: const {'skipAuth': false}, builder: (_, __) => page('HomeRoute')),
    NamedRouteDef(
      name: 'LoginRoute',
      path: '/login',
      meta: const {'skipAuth': true},
      builder: (_, __) => page('LoginRoute'),
    ),
  ];

  // Stands in for the guard's own logic; past a few calls it stops answering, so
  // the test still ends where the loop used to run forever.
  bool loopedTooLong() => ++guardCalls > 20;

  Future<FlutterErrorDetails?> pumpAndTakeError(WidgetTester tester, RootStackRouter router) async {
    FlutterErrorDetails? reported;
    final onError = FlutterError.onError;
    FlutterError.onError = (details) => reported ??= details;
    addTearDown(() => FlutterError.onError = onError);
    await pumpRouterConfigApp(tester, router.config());
    FlutterError.onError = onError;
    return reported;
  }

  // https://github.com/Milad-Akarie/auto_route_library/issues/2213
  // The reporter moved a route's auth guard, the README's AuthGuard, to the
  // router's global guards, and got a white screen with no error. A global
  // guard runs for every route, including LoginRoute, the route it redirects
  // to, so each redirect opened another redirect without end.
  // The loop must stop with an error that says what happened and how to fix it.
  for (final isAsync in [false, true]) {
    testWidgets('A global guard redirecting to a route it guards reports the loop, async: $isAsync (#2213)', (
      tester,
    ) async {
      final router = _AppRouter(
        routes: routes,
        guards: [
          AutoRouteGuard.simple((resolver, _) async {
            if (loopedTooLong()) return;
            if (isAsync) await Future<void>.delayed(Duration.zero);
            resolver.redirectUntil(NamedRoute('LoginRoute', args: resolver.next));
          }),
        ],
      );

      final error = await pumpAndTakeError(tester, router);

      expect(error?.exception.toString(), contains('A guard redirected LoginRoute to itself.'));
      expect(error?.exception.toString(), contains('resolver.routeName is LoginRoute'));
      expect(guardCalls, 2);
    });
  }

  // The README's way: a global guard lets the route it redirects to through.
  testWidgets('A global guard that lets its redirect route through shows that route (#2213)', (tester) async {
    final router = _AppRouter(
      routes: routes,
      guards: [
        AutoRouteGuard.simple((resolver, _) {
          if (loopedTooLong()) return;
          if (resolver.routeName == 'LoginRoute') {
            resolver.next();
          } else {
            resolver.redirectUntil(NamedRoute('LoginRoute', args: resolver.next));
          }
        }),
      ],
    );

    final error = await pumpAndTakeError(tester, router);

    expect(error, isNull);
    expectTopPage(router, 'LoginRoute');
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/1818
  // The reporter's global guard read router.current.meta['skipAuth'], which
  // holds the page on screen, the root at app start, instead of
  // resolver.route.meta, the route being opened. So it redirected SignInRoute to
  // itself, which ended in a stack overflow through the old
  // NavigationResolver.redirect(). With redirectUntil() it ends in the same error.
  testWidgets('A global guard reading router.current instead of resolver.route reports the loop (#1818)', (
    tester,
  ) async {
    final router = _AppRouter(
      routes: routes,
      guards: [
        AutoRouteGuard.simple((resolver, router) {
          if (loopedTooLong()) return;
          final skipAuth = router.current.meta['skipAuth'] as bool?;
          if (skipAuth == true) {
            resolver.next();
          } else {
            resolver.redirectUntil(NamedRoute('LoginRoute', args: resolver.next));
          }
        }),
      ],
    );

    final error = await pumpAndTakeError(tester, router);

    expect(error?.exception.toString(), contains('A guard redirected LoginRoute to itself.'));
  });
}
