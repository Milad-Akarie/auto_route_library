import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// flutter/flutter#122123: go_router showed "Page not found" when the app's
// initialLocation had a query string.
// Steps: start the app on '/search?term=cats&page=2'.
// Should: the search page opens and reads both query params.
void main() {
  testWidgets('An initial url with a query string opens its page with the query params', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('HomeRoute', builder: (_) => const Text('HomeRoute')),
        ),
        AutoRoute(
          path: '/search',
          page: PageInfo(
            'SearchRoute',
            builder: (data) =>
                Text('SearchRoute ${data.queryParams.getString('term')} ${data.queryParams.getInt('page')}'),
          ),
        ),
      ],
    );
    await pumpRouterApp(tester, router, initialLink: '/search?term=cats&page=2');
    expect(find.text('SearchRoute cats 2'), findsOneWidget);
    expect(router.currentUrl, '/search?term=cats&page=2');
  });
}
