import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// flutter/flutter#133928, #137513: the app starts from a link the platform
// hands it.
// Steps: set the platform's initial route to a host-only link
// ('https://www.domain.com'), then to '/home?q=test', and start the app.
// Should: the host-only link opens the home page, not an error page; the
// query of the second link is still in the url.
void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('RootRoute', builder: (_) => const Text('RootRoute')),
        ),
        AutoRoute(
          path: '/home',
          page: PageInfo('HomeRoute', builder: (_) => const Text('HomeRoute')),
        ),
      ],
    );
  });

  Future<void> startAt(WidgetTester tester, String link) {
    final dispatcher = tester.binding.platformDispatcher;
    addTearDown(dispatcher.clearDefaultRouteNameTestValue);
    dispatcher.defaultRouteNameTestValue = link;
    return pumpRouterConfigApp(tester, router.config());
  }

  testWidgets('A link with a host and no path opens the root page', (
    tester,
  ) async {
    await startAt(tester, 'https://www.domain.com');
    expect(tester.takeException(), isNull);
    expectCurrentPage(router, 'RootRoute');
  });

  testWidgets('A starting link keeps its query parameters', (tester) async {
    await startAt(tester, '/home?q=test');
    expectCurrentPage(router, 'HomeRoute');
    expect(router.currentUrl, '/home?q=test');
  });
}
