@TestOn('browser')
library;

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';
import 'browser_history.dart';

void main() {
  useRealBrowserHistory();
  setUp(rewindBrowserHistory);

  // https://github.com/Milad-Akarie/auto_route_library/issues/1755
  // A reload on a guarded page whose guard awaits before calling
  // resolver.next(true) showed the initial route instead of that page.
  // Steps: open the app on '/dashboard', as a reload does; its guard waits
  // for a stored user, then calls resolver.next(true).
  // Should: the dashboard shows and the url stays '/dashboard'.
  for (final includePrefixMatches in [false, true]) {
    testWidgets('On web, a reload on a page whose guard awaits, then calls next(true), shows that page '
        '(includePrefixMatches: $includePrefixMatches)', (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(page: _page('HomeRoute'), path: '/', initial: true),
          AutoRoute(
            page: _page('DashboardRoute'),
            path: '/dashboard',
            guards: [
              AutoRouteGuard.simple((resolver, _) async {
                await Future<void>.delayed(const Duration(milliseconds: 100));
                resolver.next();
              }),
            ],
          ),
        ],
      );
      router.routeInfoProvider(initialRouteInformation: RouteInformation(uri: Uri.parse('/dashboard')));
      await pumpRouterConfigApp(tester, router.config(includePrefixMatches: includePrefixMatches));
      await tester.pump(const Duration(milliseconds: 200));
      await settleBrowser(tester);

      expectTopPage(router, 'DashboardRoute');
      expect(browserPath, '/dashboard');
    });
  }
}

PageInfo _page(String name) => .new(name, builder: (_) => Scaffold(body: Text(name)));
