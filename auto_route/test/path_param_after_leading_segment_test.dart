import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/2071
// The report has two lines. Assumed: auto_route 9.2.2 on web, a route declared
// with each of the two paths, opened by link. The test runs on the VM and in
// Chrome; the Chrome run can't set the address bar (see CLAUDE.md), so it
// opens the link through the router.
// Steps: give the Test page the path '/:id' and, in another router, the path
// '/test/:id'; open '/5' and '/test/5'.
// Reported: '/test/:id' loaded forever and '/:id' went to Test.
// Should: each link shows Test with id 5.
void main() {
  for (final (pattern, link) in [('/:id', '/5'), ('/test/:id', '/test/5')]) {
    testWidgets('the link $link opens the route $pattern', (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            initial: true,
            page: PageInfo('HomeRoute', builder: (_) => const Text('Home')),
          ),
          AutoRoute(
            path: pattern,
            page: PageInfo(
              'TestRoute',
              builder: (_) => Builder(
                builder: (context) => Text(
                  'Test ${context.routeData.params.optString('id') ?? 'none'}',
                ),
              ),
            ),
          ),
        ],
      );
      await pumpRouterApp(tester, router, initialLink: link);
      expect(find.text('Test 5'), findsOneWidget);
      expect(router.currentUrl, link);
    });
  }
}
