import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/2046
// Open a page deep in the app, then replace() it with a route whose guard
// rejects the navigation. replace() removed the top page before running the
// guards, so a rejected route left the stack half changed: the page was gone
// from the stack but still on screen.
// A rejected replace must leave the stack as it was; an accepted one swaps the
// top page only once the guard lets the route through.
void main() {
  late bool isAllowed;
  late RootStackRouter router;

  Widget page(String name) => Scaffold(body: Center(child: Text(name)));

  setUp(() {
    isAllowed = false;
    router = RootStackRouter.build(
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
            AutoRouteGuard.simple((resolver, _) {
              if (isAllowed) {
                resolver.next();
              } else {
                unawaited(
                  resolver.redirectUntil(const NamedRoute('LoginRoute')),
                );
              }
            }),
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
  });

  List<String> stackNames() =>
      router.stack.map((page) => page.routeData.name).toList();

  testWidgets(
    'A replace rejected by a guard keeps the page it would replace (#2046)',
    (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      unawaited(router.push(const NamedRoute('DetailsRoute')));
      await tester.pumpAndSettle();

      unawaited(router.replace(const NamedRoute('ForbiddenRoute')));
      await tester.pumpAndSettle();

      expect(stackNames(), ['HomeRoute', 'DetailsRoute']);
      expectTopPage(router, 'DetailsRoute');
    },
  );

  testWidgets(
    'A replace redirected by its guard keeps the page under the redirect '
    'until the guard resolves (#2046)',
    (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      unawaited(router.push(const NamedRoute('DetailsRoute')));
      await tester.pumpAndSettle();

      unawaited(router.replace(const NamedRoute('ProtectedRoute')));
      await tester.pumpAndSettle();
      expect(stackNames(), ['HomeRoute', 'DetailsRoute', 'LoginRoute']);

      // Leaving the redirect without passing the guard rejects the replace.
      await router.maybePop();
      await tester.pumpAndSettle();
      expect(stackNames(), ['HomeRoute', 'DetailsRoute']);
      expectTopPage(router, 'DetailsRoute');
    },
  );

  testWidgets('A replace accepted by its guard swaps the top page (#2046)', (
    tester,
  ) async {
    isAllowed = true;
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.push(const NamedRoute('DetailsRoute')));
    await tester.pumpAndSettle();

    unawaited(router.replace(const NamedRoute('ProtectedRoute')));
    await tester.pumpAndSettle();

    expect(stackNames(), ['HomeRoute', 'ProtectedRoute']);
    expectTopPage(router, 'ProtectedRoute');
  });
}
