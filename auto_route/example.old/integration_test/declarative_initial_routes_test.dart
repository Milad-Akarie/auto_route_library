import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A declarative router opened by a link gets the routes of the link.
// https://github.com/Milad-Akarie/auto_route_library/issues/763
// Headless tests: auto_route/test/nested_router/declarative_initial_routes_test.dart
// and auto_route/test/web/declarative_router_url_web_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('declarative initial routes', () {
    // Steps: a page at '/' builds AutoRouter.declarative with the list at ''
    // and the details at 'book/:id'. Its routes callback reads the routes of
    // the link from its handler. Open the app at '/book/1'.
    // Should: the page shows book 1, and the url stays at it.
    testWidgets('a link to a nested page shows that page', (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            initial: true,
            page: PageInfo(
              'HostRoute',
              builder: (_) => AutoRouter.declarative(
                routes: (handler) => [
                  const PageRouteInfo('ListRoute'),
                  ...?handler.initialPendingRoutes?.where(
                    (route) => route.routeName == 'DetailsRoute',
                  ),
                ],
              ),
            ),
            children: [
              AutoRoute(path: '', page: _page('ListRoute')),
              AutoRoute(path: 'book/:id', page: _page('DetailsRoute')),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router, initialLink: '/book/1');
      expect(find.text('DetailsRoute 1'), findsOneWidget);
      expect(router.currentUrl, '/book/1');
    });
  });
}

PageInfo _page(String name) => .new(
  name,
  builder: (data) {
    final id = data.params.optString('id');
    return Scaffold(body: Text(id == null ? name : '$name $id'));
  },
);
