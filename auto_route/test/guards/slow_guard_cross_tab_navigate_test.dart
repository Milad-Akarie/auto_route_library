import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/852
// Steps: MainTabs at '' has an async guard (it waits, as the reporter's
// web-service check did, then calls next). Its tabs are DashboardRouter
// (DashboardPage) and ShowsRouter (ShowsListingPage, ShowDetailsPage). On
// DashboardPage, call navigateTo(MainTabsRoute(children: [ShowsRouter
// (children: [ShowsListingRoute, ShowDetailsRoute])])).
// Reported: mostly the screen refreshed and showed DashboardPage again.
// Should: ShowDetailsPage is shown, once the guard has let the link through.
void main() {
  testWidgets('navigating across tabs through a slow guard on the tabs route '
      'shows the target page', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'MainTabsRoute',
            builder: (_) => AutoTabsRouter(
              routes: const [
                PageRouteInfo('DashboardRouter'),
                PageRouteInfo('ShowsRouter'),
              ],
              builder: (_, child) => Scaffold(body: child),
            ),
          ),
          guards: [
            AutoRouteGuard.simple((resolver, _) async {
              await Future<void>.delayed(const Duration(milliseconds: 200));
              resolver.next();
            }),
          ],
          children: [
            AutoRoute(
              path: 'dashboard',
              page: PageInfo(
                'DashboardRouter',
                builder: (_) => const AutoRouter(),
              ),
              children: [
                AutoRoute(
                  path: '',
                  page: PageInfo(
                    'DashboardRoute',
                    builder: (_) => Builder(
                      builder: (context) => TextButton(
                        onPressed: () => unawaited(
                          context.navigateTo(
                            const PageRouteInfo(
                              'MainTabsRoute',
                              initialChildren: [
                                PageRouteInfo(
                                  'ShowsRouter',
                                  initialChildren: [
                                    PageRouteInfo('ShowsListingRoute'),
                                    PageRouteInfo('ShowDetailsRoute'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        child: const Text('Continue watching'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            AutoRoute(
              path: 'shows',
              page: PageInfo('ShowsRouter', builder: (_) => const AutoRouter()),
              children: [
                AutoRoute(
                  path: '',
                  page: PageInfo(
                    'ShowsListingRoute',
                    builder: (_) => const Text('Shows listing'),
                  ),
                ),
                AutoRoute(
                  path: 'details',
                  page: PageInfo(
                    'ShowDetailsRoute',
                    builder: (_) => const Text('Show details'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Continue watching'), findsOneWidget);

    await tester.tap(find.text('Continue watching'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Show details'), findsOneWidget);
    expect(find.text('Continue watching'), findsNothing);
  });
}
