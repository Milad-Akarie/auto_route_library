import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// flutter/flutter#113812: redirecting a route to one of its own sub-routes
// failed with "too many redirects".
// The reporter's app: '/' and '/explore' both redirect to '/explore/schools',
// a child of 'explore'. Open '/', '/explore' and '/explore/schools' as links.
// Should: each shows the schools page at '/explore/schools', with no error.
void main() {
  Widget page(String name) => Text(name);

  for (final link in ['/', '/explore', '/explore/schools']) {
    testWidgets('A link to $link lands on the schools page with redirect routes', (tester) async {
      final router = RootStackRouter.build(
        routes: [
          RedirectRoute(path: '/', redirectTo: '/explore/schools'),
          RedirectRoute(path: '/explore', redirectTo: '/explore/schools'),
          NamedRouteDef(
            name: 'ExploreRoute',
            path: '/explore',
            builder: (_, _) => const AutoRouter(),
            children: [
              NamedRouteDef(name: 'SchoolsRoute', path: 'schools', builder: (_, _) => page('schools')),
              NamedRouteDef(name: 'TeachersRoute', path: 'teachers', builder: (_, _) => page('teachers')),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router, initialLink: link);
      expect(tester.takeException(), isNull);
      expect(find.text('schools'), findsOneWidget);
      expect(router.currentUrl, '/explore/schools');
    });
  }

  testWidgets('A guard on a parent route redirects its bare path to its own child', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'ExploreRoute',
          path: '/explore',
          guards: const [_ToSchoolsGuard()],
          builder: (_, _) => const AutoRouter(),
          children: [NamedRouteDef(name: 'SchoolsRoute', path: 'schools', builder: (_, _) => page('schools'))],
        ),
      ],
    );
    await pumpRouterApp(tester, router, initialLink: '/explore');
    expect(tester.takeException(), isNull);
    expect(find.text('schools'), findsOneWidget);
    expect(router.currentUrl, '/explore/schools');
  });
}

class _ToSchoolsGuard extends AutoRouteGuard {
  const new();

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (resolver.route.stringMatch == 'explore' || resolver.route.children?.isEmpty != false) {
      unawaited(resolver.redirectUntil(const NamedRoute('SchoolsRoute')));
    } else {
      resolver.next();
    }
  }
}
