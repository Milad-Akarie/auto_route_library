import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));

// Reproduction for https://github.com/Milad-Akarie/auto_route_library/issues/1394
// Setup, as reported: an AuthGuard on a page that calls resolver.next(false)
// when the user is not signed in; the app is opened from a push notification
// whose link has a custom scheme. Button navigation was blocked; the link was
// not.
// Steps: the app runs on its home page; the platform hands it the link
// '/secret/details' (a plain path), then 'myapp:///secret/details' (custom
// scheme, no host; 'myapp://secret/details' drops 'secret'
// (the parser reads only the path), a separate issue), while the guard rejects.
// Should: the home page stays; the guarded page never shows.
void main() {
  RootStackRouter buildRouter(List<String> calls) => .build(
    routes: [
      AutoRoute(page: _page('HomeRoute'), path: '/'),
      AutoRoute(
        page: _page('SecretRoute'),
        path: '/secret/details',
        guards: [
          AutoRouteGuard.simple((resolver, _) {
            calls.add('asked');
            resolver.reject();
          }),
        ],
      ),
    ],
  );

  for (final link in ['/secret/details', 'myapp:///secret/details']) {
    testWidgets('A link to a guarded page that rejects keeps the home page '
        '($link, #1394)', (tester) async {
      final calls = <String>[];
      final router = buildRouter(calls);
      await pumpRouterApp(tester, router);

      await tester.binding.handlePushRoute(link);
      await tester.pumpAndSettle();

      expect(calls, ['asked']);
      expect(find.text('SecretRoute'), findsNothing);
      expectCurrentPage(router, 'HomeRoute');
      expect(router.stack.map((e) => e.routeData.name), ['HomeRoute']);
    });
  }

  testWidgets('A cold start from a link to a guarded page that rejects does '
      'not show the page (#1394)', (tester) async {
    final calls = <String>[];
    final router = buildRouter(calls);
    await pumpRouterApp(tester, router, initialLink: '/secret/details');

    expect(calls, ['asked']);
    expect(find.text('SecretRoute'), findsNothing);
  });
}
