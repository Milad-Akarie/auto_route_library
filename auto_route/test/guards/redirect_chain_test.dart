import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

PageInfo _page(String name) => .new(name, builder: (_) => Scaffold(body: Text(name)));

// flutter/flutter#178984 and #188014: in go_router 16 a redirect that led to
// a path with a redirect of its own stopped after the first one.
// Steps: open '/', which redirects to '/a', which redirects to '/b'; once
// with RedirectRoutes and once with a guard on '/a' that redirects.
// Should: the app ends on '/b', with the query and fragment of the link.
void main() {
  testWidgets('Chained RedirectRoutes end on the last page with the link\'s query and fragment '
      '(flutter/flutter#178984)', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        RedirectRoute(path: '/', redirectTo: '/a'),
        RedirectRoute(path: '/a', redirectTo: '/b'),
        AutoRoute(page: _page('BRoute'), path: '/b'),
      ],
    );
    await pumpRouterApp(tester, router, initialLink: '/?q=1#frag');

    expectCurrentPage(router, 'BRoute');
    expect(router.currentUrl, '/b?q=1#frag');
    expect(router.stack, hasLength(1));
  });

  testWidgets('A guard redirecting to another page ends on that page after a RedirectRoute '
      '(flutter/flutter#188014)', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        RedirectRoute(path: '/', redirectTo: '/a'),
        AutoRoute(
          page: _page('ARoute'),
          path: '/a',
          guards: [
            AutoRouteGuard.simple((resolver, _) => unawaited(resolver.redirectUntil(const NamedRoute('BRoute')))),
          ],
        ),
        AutoRoute(page: _page('BRoute'), path: '/b'),
      ],
    );
    await pumpRouterApp(tester, router, initialLink: '/');

    expectCurrentPage(router, 'BRoute');
    expect(router.stack.map((p) => p.name), ['BRoute']);
  });

  // flutter/flutter#182469: a redirect lost the query parameters.
  testWidgets('A RedirectRoute keeps the query parameters of the link (flutter/flutter#182469)', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        RedirectRoute(path: '/old', redirectTo: '/new'),
        AutoRoute(page: _page('NewRoute'), path: '/new'),
      ],
    );
    await pumpRouterApp(tester, router, initialLink: '/old?ketchup=true&mustard=yes');

    expectCurrentPage(router, 'NewRoute');
    expect(router.current.queryParams.getBool('ketchup'), isTrue);
    expect(router.current.queryParams.getString('mustard'), 'yes');
  });
}
