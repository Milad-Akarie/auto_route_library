import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A guard that redirects a route to itself again reports the loop instead of
// running forever behind a blank screen.
// https://github.com/Milad-Akarie/auto_route_library/issues/2213
// https://github.com/Milad-Akarie/auto_route_library/issues/1818
// Headless test: auto_route/test/guards/redirect_loop_test.dart
class _AppRouter extends RootStackRouter {
  _AppRouter({required this.guards, required this.routes});

  @override
  final List<AutoRouteGuard> guards;

  @override
  final List<AutoRoute> routes;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Widget page(String name) => Scaffold(body: SafeArea(child: Text(name)));

  final routes = [
    NamedRouteDef(name: 'HomeRoute', path: '/', builder: (_, _) => page('HomeRoute')),
    NamedRouteDef(name: 'LoginRoute', path: '/login', builder: (_, _) => page('LoginRoute')),
  ];

  // Steps: open an app whose global guard always calls
  // redirectUntil(LoginRoute()), the route guard the reporter moved to the
  // router's guards.
  // Should: the guard runs twice, for HomeRoute and for LoginRoute, and the
  // second redirect reports an error that names LoginRoute and the fix.
  testWidgets('A global guard redirecting to a route it guards reports the loop (#2213)', (tester) async {
    var guardCalls = 0;
    final router = _AppRouter(
      routes: routes,
      guards: [
        AutoRouteGuard.simple((resolver, _) {
          // past a few calls the guard stops answering, so the test still ends where the loop ran forever
          if (++guardCalls > 20) return;
          resolver.redirectUntil(NamedRoute('LoginRoute', args: resolver.next));
        }),
      ],
    );
    FlutterErrorDetails? reported;
    final onError = FlutterError.onError;
    FlutterError.onError = (details) => reported ??= details;
    addTearDown(() => FlutterError.onError = onError);

    await pumpRouterAppWithConfig(tester, router);
    FlutterError.onError = onError;

    expect(reported?.exception.toString(), contains('A guard redirected LoginRoute to itself.'));
    expect(guardCalls, 2);
  });
}
