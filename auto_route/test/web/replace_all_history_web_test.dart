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

  // flutter/flutter#169481: on an iPhone home screen web app, the edge
  // swipe, the browser's back step, went back to the page left with go().
  // Open FirstRoute, replaceAll with SecondRoute, then replaceAll with
  // FirstRoute: each replaces the browser's entry, so no back step leads to
  // the page left. navigate() adds an entry, as a link does.
  testWidgets('replaceAll on web leaves no browser entry to go back to', (tester) async {
    final router = SimpleRouter();
    await pumpRouterConfigApp(tester, router.config());
    await settleBrowser(tester);
    final start = browserSerialCount;

    unawaited(router.replaceAll([const SecondRoute()]));
    await settleBrowser(tester);
    expectCurrentPage(router, SecondRoute.name);
    expect(browserPath, '/second-route');
    expect(browserSerialCount, start);

    unawaited(router.replaceAll([const FirstRoute()]));
    await settleBrowser(tester);
    expectCurrentPage(router, FirstRoute.name);
    expect(browserPath, '/');
    expect(browserSerialCount, start, reason: 'after settleBrowser(tester)');
  });
}
