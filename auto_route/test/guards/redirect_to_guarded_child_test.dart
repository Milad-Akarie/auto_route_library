import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

import '../named_page.dart';
import '../router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/1422
  // Reported: on cold start at '/', a RedirectRoute('' -> 'home') inside
  // MainRoute opened HomeRouter without calling the guard on HomeRouter.
  // Steps: MainRoute '/' with children RedirectRoute('' -> 'home') and
  // HomeRouter 'home', guarded by AuthGuard; the user is signed out, so the
  // guard pushes LoginRoute and rejects the navigation. Start at '/'.
  // Should: the guard runs once and LoginRoute shows; HomeRoute doesn't.
  testWidgets(
    'The guard of the route a RedirectRoute leads to runs on cold start',
    (tester) async {
      var guardCalls = 0;
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef.shell(
            name: 'MainRoute',
            path: '/',
            children: [
              RedirectRoute(path: '', redirectTo: 'home'),
              NamedRouteDef.shell(
                name: 'HomeRouter',
                path: 'home',
                guards: [
                  AutoRouteGuard.simple((resolver, guardedRouter) {
                    guardCalls++;
                    unawaited(
                      guardedRouter.push(const NamedRoute('LoginRoute')),
                    );
                    resolver.reject();
                  }),
                ],
                children: [
                  NamedRouteDef(
                    name: 'HomeRoute',
                    path: '',
                    builder: (_, _) => const NamedPage('HomeRoute'),
                  ),
                ],
              ),
            ],
          ),
          NamedRouteDef(
            name: 'LoginRoute',
            path: '/login',
            builder: (_, _) => const NamedPage('LoginRoute'),
          ),
          RedirectRoute(path: '*', redirectTo: '/'),
        ],
      );
      await pumpRouterConfigApp(tester, router.config());

      expect(guardCalls, 1);
      expect(router.topRoute.name, 'LoginRoute');
      expect(find.text('LoginRoute'), findsOneWidget);
      expect(find.text('HomeRoute'), findsNothing);
    },
  );
}
