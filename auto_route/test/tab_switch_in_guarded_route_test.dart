import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// flutter/flutter#117680: in go_router, context.go from a tab inside a shell
// ran the top-level redirect again and sent the user to the wrong place.
// Setup: a signed-in app whose '/app' route has a guard that lets the user in,
// and tabs 'home' and 'profile' inside it.
// Steps: open '/app', switch tabs with navigate and with setActiveIndex.
// Should: each switch shows the tab asked for, at its url, and no redirect
// takes the user elsewhere. A navigate to a url inside '/app' asks its guard
// again, as every navigation to a guarded route does; setActiveIndex does not.
void main() {
  testWidgets('Switching tabs inside a guarded route shows the tab asked for without a redirect', (tester) async {
    var guardCalls = 0;
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(path: '/login', page: _page('LoginRoute')),
        AutoRoute(
          path: '/app',
          initial: true,
          guards: [
            AutoRouteGuard.simple((resolver, _) {
              guardCalls++;
              resolver.next();
            }),
          ],
          page: PageInfo(
            'AppRoute',
            builder: (_) => const AutoTabsScaffold(routes: [NamedRoute('HomeRoute'), NamedRoute('ProfileRoute')]),
          ),
          children: [
            AutoRoute(path: 'home', page: _page('HomeRoute')),
            AutoRoute(path: 'profile', page: _page('ProfileRoute')),
          ],
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    expect(guardCalls, 1);
    expect(find.text('HomeRoute'), findsOneWidget);

    unawaited(router.navigatePath('/app/profile'));
    await tester.pumpAndSettle();
    final callsAfterNavigate = guardCalls;
    expect(find.text('ProfileRoute'), findsOneWidget);
    router.innerRouterOf<TabsRouter>('AppRoute')!.setActiveIndex(0);
    await tester.pumpAndSettle();
    expect(find.text('HomeRoute'), findsOneWidget);
    expect(router.currentUrl, '/app/home');
    // setActiveIndex stays inside the route and asks no guard of it.
    expect(guardCalls, callsAfterNavigate);
  });
}

PageInfo _page(String name) => .new(name, builder: (_) => Scaffold(body: Text(name)));
