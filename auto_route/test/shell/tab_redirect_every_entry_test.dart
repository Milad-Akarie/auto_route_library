import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/flutter/flutter/issues/194209
// Setup: tabs A and B; tab B's guard redirects to a welcome page at the root
// each time tab B is entered.
// Steps: from tab A, switch to tab B: the welcome page shows. Cancel it by
// navigating to tab A, or by popping it. Switch to tab B again.
// Should: the guard runs again and the welcome page shows on the second
// entry too.
void main() {
  for (final (how, cancel) in [
    ("navigatePath('/a')", (StackRouter router) => unawaited(router.navigatePath('/a'))),
    ('popping the welcome page', (StackRouter router) => router.pop()),
  ]) {
    testWidgets('A tab redirect cancelled by $how shows again on the next entry', (tester) async {
      var guardCalls = 0;
      final guard = AutoRouteGuard.simple((resolver, _) {
        guardCalls++;
        unawaited(resolver.redirectUntil(const _Route('WelcomeRoute')));
      });
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: PageInfo(
              'HomeRoute',
              builder: (_) => const AutoTabsRouter(routes: [_Route('ARoute'), _Route('BRoute')]),
            ),
            children: [
              AutoRoute(path: 'a', page: _page('ARoute')),
              AutoRoute(path: 'b', page: _page('BRoute'), guards: [guard]),
            ],
          ),
          AutoRoute(path: '/b/welcome', page: _page('WelcomeRoute')),
        ],
      );
      await pumpRouterApp(tester, router);
      final tabs = router.innerRouterOf<TabsRouter>('HomeRoute')!;

      for (var entry = 1; entry <= 2; entry++) {
        tabs.setActiveIndex(1);
        await tester.pumpAndSettle();
        expect(guardCalls, entry);
        expectTopPage(router, 'WelcomeRoute');

        cancel(router);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(router.stack.map((page) => page.name), ['HomeRoute']);
        expect(tabs.activeIndex, 0);
        expect(find.text('ARoute'), findsOneWidget);
      }
    });
  }
}

PageInfo _page(String name) => .new(name, builder: (_) => Scaffold(body: Text(name)));

class _Route extends PageRouteInfo<void> {
  const _Route(super.name);
}
