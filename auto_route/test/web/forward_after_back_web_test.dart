@TestOn('browser')
library;

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

import '../main_router.dart';
import '../nested_router/router.dart';
import '../router_test_utils.dart';
import 'browser_history.dart';

void main() {
  useRealBrowserHistory();
  setUp(rewindBrowserHistory);

  // flutter/flutter#147229: in go_router, with pushes reflected in the
  // url, the browser's forward button after back threw "Location cannot be
  // empty". auto_route always puts a pushed page in the url.
  // Steps: push SecondHostRoute, push SecondNested2Route in its nested
  // router, press the browser's back button, then its forward button.
  // Should: no exception, SecondNested2Route is on top again with its url.
  testWidgets(
    'The browser forward button after back returns to a page pushed in a '
    'nested router',
    (tester) async {
      final router = NestedRouter();
      await pumpRouterConfigApp(tester, router.config());
      await settleBrowser(tester);
      unawaited(router.push(SecondHostRoute()));
      await settleBrowser(tester);
      unawaited(
        router
            .innerRouterOf<StackRouter>(SecondHostRoute.name)!
            .push(const SecondNested2Route()),
      );
      await settleBrowser(tester);
      final pushedPath = browserPath;
      expectTopPage(router, SecondNested2Route.name);

      await pressBrowserBack(tester);
      expectTopPage(router, SecondNested1Route.name);

      await pressBrowserForward(tester);
      expect(tester.takeException(), isNull);
      expectTopPage(router, SecondNested2Route.name);
      expect(browserPath, pushedPath);

      await pressBrowserBack(tester);
      await pressBrowserBack(tester);
      expectCurrentPage(router, FirstRoute.name);
      await pressBrowserForward(tester);
      expect(
        tester.takeException(),
        isNull,
        reason: 'after pressBrowserForward(tester)',
      );
      expect(router.current.name, SecondHostRoute.name);
    },
  );
}
