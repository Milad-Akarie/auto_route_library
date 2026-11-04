@TestOn('browser')
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import '../main_router.dart';
import '../router_test_utils.dart';
import '../simple_router/router.dart';
import 'browser_history.dart';

void main() {
  useRealBrowserHistory();

  setUp(rewindBrowserHistory);

  // flutter/flutter#128334: in go_router, the browser back button returned to
  // a page left with pushReplacement. go_router closed it as intended: its
  // replace adds a browser entry. auto_route's replace takes the browser entry
  // of the page it replaces.
  // Steps: open FirstRoute, push SecondRoute, replace it with ThirdRoute,
  // then press the browser back button.
  // Should: back shows FirstRoute, not SecondRoute.
  testWidgets('On web, the browser back button after replace skips the replaced page (flutter/flutter#128334)', (
    tester,
  ) async {
    final router = SimpleRouter();
    await pumpRouterConfigApp(tester, router.config());
    await settleBrowser(tester);
    unawaited(router.push(const SecondRoute()));
    await settleBrowser(tester);
    unawaited(router.replace(const ThirdRoute()));
    await settleBrowser(tester);
    expectCurrentPage(router, ThirdRoute.name);

    await pressBrowserBack(tester);
    expectCurrentPage(router, FirstRoute.name);
    expect(browserPath, '/');
  });
}
