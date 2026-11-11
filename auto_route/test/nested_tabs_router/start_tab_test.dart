import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// Pins the README section "Choosing the start tab", under Tab Navigation:
// marking a tab route `initial: true` makes it the tab the tabs open on, so
// the tabs' own url, '/dashboard', leads to it, '/dashboard/posts', and so does
// the tabs' route without children.
// Steps: a Dashboard route whose tabs are Users, Posts and Settings, with
// Posts marked initial; open the dashboard by its route and by its url, with
// the tabs given in `routes` and taken from the config.
void main() {
  for (final hasRoutes in [true, false]) {
    final tabsFrom = hasRoutes ? 'the tabs listed in routes' : 'the config';

    testWidgets('By route, the tabs start on the initial tab, with $tabsFrom', (
      tester,
    ) async {
      final router = _router(hasRoutes: hasRoutes);
      await pumpRouterApp(tester, router);

      unawaited(router.navigate(const PageRouteInfo<void>('Dashboard')));
      await tester.pumpAndSettle();

      expect(router.innerRouterOf<TabsRouter>('Dashboard')!.activeIndex, 1);
      expect(find.text('Posts'), findsOneWidget);
      expect(router.currentUrl, '/dashboard/posts');
    });

    testWidgets('By url, the tabs start on the initial tab, with $tabsFrom', (
      tester,
    ) async {
      final router = _router(hasRoutes: hasRoutes);
      await pumpRouterApp(tester, router);

      unawaited(router.navigatePath('/dashboard'));
      await tester.pumpAndSettle();

      expect(router.innerRouterOf<TabsRouter>('Dashboard')!.activeIndex, 1);
      expect(find.text('Posts'), findsOneWidget);
      expect(router.currentUrl, '/dashboard/posts');
    });
  }
}

RootStackRouter _router({required bool hasRoutes}) => .build(
  routes: [
    AutoRoute(page: _page('Home'), path: '/', initial: true),
    AutoRoute(
      page: PageInfo(
        'Dashboard',
        builder: (_) => AutoTabsRouter(
          routes: hasRoutes
              ? const [
                  PageRouteInfo<void>('Users'),
                  PageRouteInfo<void>('Posts'),
                  PageRouteInfo<void>('Settings'),
                ]
              : null,
        ),
      ),
      path: '/dashboard',
      children: [
        AutoRoute(page: _page('Users'), path: 'users'),
        AutoRoute(page: _page('Posts'), path: 'posts', initial: true),
        AutoRoute(page: _page('Settings'), path: 'settings'),
      ],
    ),
  ],
);

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));
