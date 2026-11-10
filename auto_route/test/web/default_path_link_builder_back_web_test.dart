@TestOn('browser')
library;

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';
import 'browser_history.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/1965
// Setup: routes '/' and '/user/:id', and
// `config(deepLinkBuilder: (link) => DeepLink.defaultPath)`, so every link the
// platform reports is answered with '/'.
// Steps: open the user page through the app, press the browser's back button.
// Reported: after back the Flutter inspector showed two copies of the user
// page in the widget tree, where before it showed one.
// Should: the user page appears once, or not at all, and the home page shows.
// Offstage pages count, as the inspector lists them. The stack holds the home
// page alone: a back that also ran the default-path link and pushed its page
// would leave a second copy of a page offstage.
void main() {
  useRealBrowserHistory();

  late RootStackRouter router;
  setUp(() async {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('HomeRoute', (_) => 'Home'), path: '/'),
        AutoRoute(
          page: _page(
            'UserRoute',
            (data) => 'User ${data.params.getString('id')}',
          ),
          path: '/user/:id',
        ),
      ],
    );
    await rewindBrowserHistory();
  });

  testWidgets(
    'On web, back from a page keeps at most one copy of it when every link '
    'is answered with the default path',
    (tester) async {
      await pumpRouterConfigApp(
        tester,
        router.config(deepLinkBuilder: (link) => DeepLink.defaultPath),
      );
      await settleBrowser(tester);
      unawaited(router.navigatePath('/user/1'));
      await settleBrowser(tester);
      expect(find.text('User 1'), findsOneWidget);
      expect(browserPath, '/user/1');

      await pressBrowserBack(tester);
      expect(
        find.text('User 1', skipOffstage: false).evaluate().length,
        lessThanOrEqualTo(1),
        reason: 'user pages in the tree after back',
      );
      expect(find.text('Home'), findsOneWidget);
      expect(router.stack.map((page) => page.name), ['HomeRoute']);
      expect(browserPath, '/');
    },
  );
}

PageInfo _page(String name, String Function(RouteData<Object?> data) text) =>
    .new(name, builder: (data) => Scaffold(body: Text(text(data))));
