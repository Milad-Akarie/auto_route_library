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

  // https://github.com/Milad-Akarie/auto_route_library/issues/1108
  // Reported on web: a reload on '/admin/gazetteer' went to '/admin', or to
  // its initial child when one was set, instead of staying on the page.
  // Steps: CustomRoutes HomeRoute '/' (initial) and AdminLayoutRoute
  // '/admin', a router of DashboardRoute and GazetteerRoute; open the app at
  // '/admin/gazetteer', as a reload does, with and without DashboardRoute as
  // the initial child.
  // Should: GazetteerRoute shows and the url stays '/admin/gazetteer'.
  for (final dashboardInitial in [false, true]) {
    testWidgets(
      'On web, a reload on a nested page keeps it (initial dashboard: '
      '$dashboardInitial)',
      (tester) async {
        final router = RootStackRouter.build(
          routes: [
            CustomRoute(
              page: _page('HomeRoute'),
              path: '/',
              initial: true,
              transitionsBuilder: TransitionsBuilders.fadeIn,
            ),
            CustomRoute(
              page: PageInfo(
                'AdminLayoutRoute',
                builder: (_) => const AutoRouter(),
              ),
              path: '/admin',
              children: [
                CustomRoute(
                  page: _page('DashboardRoute'),
                  path: 'dashboard',
                  initial: dashboardInitial,
                  transitionsBuilder: TransitionsBuilders.fadeIn,
                ),
                CustomRoute(
                  page: _page('GazetteerRoute'),
                  path: 'gazetteer',
                  transitionsBuilder: TransitionsBuilders.fadeIn,
                ),
              ],
            ),
          ],
        );
        openBrowserAt(tester, '/admin/gazetteer');
        await pumpRouterConfigApp(tester, router.config());
        await settleBrowser(tester);

        expect(find.text('GazetteerRoute'), findsOneWidget);
        expect(browserPath, '/admin/gazetteer');
      },
    );
  }
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));
