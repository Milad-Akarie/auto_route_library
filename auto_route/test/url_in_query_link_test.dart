import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// flutter/flutter#93295: a link whose query holds an unencoded
// url, demoapp://dl.demo.app/passwordless?token=abc123&targetRoute=demoapp://dl.demo.app/passwordless.
// On an Android cold start the engine handed the Router four links, cut
// after 'demoapp:', 'demoapp:/', 'demoapp://dl.demo.app' and in full, and
// the app stacked four pages. That split is Android's, before Dart sees the
// link; it is left unchecked on a device here.
// Should: the link opens one page holding the whole query; and if the
// platform hands the four cut links in a row, one page is still left, with
// the last link's query.
void main() {
  const query = 'token=abc123&targetRoute=demoapp://dl.demo.app/passwordless';

  RootStackRouter buildRouter() => .build(
    routes: [
      AutoRoute(
        path: '/',
        page: PageInfo('HomeRoute', builder: (_) => const Text('HomeRoute')),
      ),
      AutoRoute(
        path: '/passwordless',
        page: PageInfo(
          'PasswordlessRoute',
          builder: (_) => const Text('Passwordless'),
        ),
      ),
    ],
  );

  testWidgets(
    'a link with an unencoded url in its query opens one page with the whole query',
    (tester) async {
      final router = buildRouter();
      await pumpRouterApp(tester, router, initialLink: '/passwordless?$query');

      expect(router.stack.map((page) => page.name), [
        'HomeRoute',
        'PasswordlessRoute',
      ]);
      expect(router.topRoute.queryParams.rawMap, {
        'token': 'abc123',
        'targetRoute': 'demoapp://dl.demo.app/passwordless',
      });
    },
  );

  testWidgets('the link cut four ways in a row leaves one page', (
    tester,
  ) async {
    final router = buildRouter();
    await pumpRouterApp(tester, router);
    for (final targetRoute in [
      'demoapp:',
      'demoapp:/',
      'demoapp://dl.demo.app',
      'demoapp://dl.demo.app/passwordless',
    ]) {
      await tester.binding.handlePushRoute(
        '/passwordless?token=abc123&targetRoute=$targetRoute',
      );
    }
    await tester.pumpAndSettle();

    expect(router.stack.map((page) => page.name), [
      'HomeRoute',
      'PasswordlessRoute',
    ]);
    expect(
      router.topRoute.queryParams.getString('targetRoute'),
      'demoapp://dl.demo.app/passwordless',
    );
    expect(find.text('Passwordless'), findsOneWidget);
  });
}
