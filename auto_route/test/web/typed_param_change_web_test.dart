@TestOn('browser')
library;

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:web/web.dart' show window;

import '../router_test_utils.dart';
import 'browser_history.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/701
// Setup: a web app with a page at '/test/:id' that shows its id, and a home
// page at '/'.
// Steps: open the page for id 1 (once through the app, once by typing it into
// the address bar), then type the same path with another id into the address
// bar, so only the path param changes.
// Reported: in Firefox and Chrome nothing happened until the page was
// reloaded; the page kept showing the old id.
// Should: the page shows the new id and the address bar keeps it. The
// address bar is the one thing only a real browser run proves; this runs in
// Chrome's headless test runner with the real history.
void main() {
  useRealBrowserHistory();

  late RootStackRouter router;
  setUp(() async {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('HomeRoute', (_) => 'Home'), path: '/'),
        AutoRoute(
          page: _page(
            'TestRoute',
            (data) => 'Test ${data.params.getString('id')}',
          ),
          path: '/test/:id',
        ),
      ],
    );
    await rewindBrowserHistory();
  });

  testWidgets('On web, typing only a new id into the address bar shows it', (
    tester,
  ) async {
    await pumpRouterConfigApp(tester, router.config());
    await settleBrowser(tester);

    await browserMove(tester, () => window.location.hash = '/test/1');
    expect(find.text('Test 1'), findsOneWidget);
    expect(browserPath, '/test/1');

    await browserMove(tester, () => window.location.hash = '/test/2');
    expect(find.text('Test 2'), findsOneWidget);
    expect(browserPath, '/test/2');
    expect(router.currentUrl, '/test/2');
  });

  testWidgets(
    'On web, typing a new id after opening the page through the app shows it',
    (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      await settleBrowser(tester);
      unawaited(router.navigatePath('/test/34'));
      await settleBrowser(tester);
      expect(find.text('Test 34'), findsOneWidget);

      await browserMove(tester, () => window.location.hash = '/test/107');
      expect(find.text('Test 107'), findsOneWidget);
      expect(browserPath, '/test/107');
      expect(router.currentUrl, '/test/107');
    },
  );
}

PageInfo _page(String name, String Function(RouteData<Object?> data) text) =>
    .new(name, builder: (data) => Scaffold(body: Text(text(data))));
