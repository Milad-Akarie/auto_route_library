import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/1318
// Setup: a router with an initial route '/' and a page '/books/:id'; the app
// passes only the router, with no initialRoutes or initialDeepLink.
// Steps: start the app from a link to '/books/5', as a cold start does.
// Should: the book page shows, with no "Can not resolve initial route".
void main() {
  RootStackRouter buildRouter() => .build(
    routes: [
      AutoRoute(
        path: '/',
        page: PageInfo('HomeRoute', builder: (_) => const Text('Home')),
        initial: true,
      ),
      AutoRoute(
        path: '/books/:id',
        page: PageInfo(
          'BookRoute',
          builder: (data) => Text('Book ${data.params.getString('id')}'),
        ),
      ),
    ],
  );

  testWidgets(
    'A cold start from a deep link opens that page, with the delegate and '
    'parser',
    (tester) async {
      final router = buildRouter();
      await pumpRouterApp(tester, router, initialLink: '/books/5');
      expect(tester.takeException(), isNull);
      expect(find.text('Book 5'), findsOneWidget);
      expect(router.urlState.url, '/books/5');
    },
  );

  testWidgets('A cold start without a link opens the initial route', (
    tester,
  ) async {
    final router = buildRouter();
    await pumpRouterApp(tester, router);
    expect(find.text('Home'), findsOneWidget);
  });
}
