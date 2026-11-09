import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));

// Reproduction for https://github.com/Milad-Akarie/auto_route_library/issues/1687
// Setup, as reported (auto_route 7.8): a RedirectRoute '/upcoming' to
// '/shows/upcoming'; a guarded main page at '/' with a 'shows' child that
// holds 'watchlist' and 'upcoming'. The maintainer's fix (7.8.3) was to read
// the host of 'myapp://shows/upcoming' as the first path segment.
// Steps: the app shows shows/watchlist; the platform hands it
// 'myapp://shows/upcoming', '/shows/upcoming' and '/upcoming' in turn.
// Should: each one shows the upcoming page.
// Note: 'myapp://shows/upcoming' reaches the router as '/upcoming' (the parser
// drops the host), which the RedirectRoute then sends to the right page; that
// is the reporter's setup.
void main() {
  RootStackRouter buildRouter() => .build(
    routes: [
      RedirectRoute(path: '/upcoming', redirectTo: '/shows/upcoming'),
      AutoRoute(
        page: PageInfo('MainRoute', builder: (_) => const AutoRouter()),
        path: '/',
        guards: [AutoRouteGuard.simple((resolver, _) => resolver.next())],
        children: [
          AutoRoute(
            page: PageInfo('ShowsRoute', builder: (_) => const AutoRouter()),
            path: 'shows',
            initial: true,
            children: [
              AutoRoute(
                page: _page('WatchlistRoute'),
                path: 'watchlist',
                initial: true,
              ),
              AutoRoute(page: _page('UpcomingRoute'), path: 'upcoming'),
            ],
          ),
        ],
      ),
    ],
  );

  for (final link in [
    'myapp://shows/upcoming',
    '/shows/upcoming',
    '/upcoming',
  ]) {
    testWidgets('The link $link opens the upcoming page (#1687)', (
      tester,
    ) async {
      final router = buildRouter();
      await pumpRouterApp(tester, router);
      expect(find.text('WatchlistRoute'), findsOneWidget);

      await tester.binding.handlePushRoute(link);
      await tester.pumpAndSettle();

      expect(find.text('UpcomingRoute'), findsOneWidget);
      expect(router.urlState.path, '/shows/upcoming');
    });
  }
}
