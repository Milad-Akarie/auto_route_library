// Runs only in Chrome, `flutter test --platform chrome`: it needs the
// browser's own history, which the VM runner doesn't have, so the VM skips it.
@TestOn('browser')
library;

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

import '../neglect_when_router.dart';
import '../router_test_utils.dart';
import 'browser_history.dart';

// Pins the README section "Keeping a url out of the address bar", under
// Working with Paths: a url `neglectWhen` matches opens its page while the
// address bar keeps the url before it and no history entry is added, so the
// browser's back button skips that page.
// Steps: an app whose config neglects urls under '/checkout'; from Home, push
// Checkout, then Done, then press the browser's back button.
void main() {
  useRealBrowserHistory();
  setUp(rewindBrowserHistory);

  testWidgets('A neglected url adds no browser entry, so back skips it', (
    tester,
  ) async {
    final router = neglectingRouter();
    await pumpRouterConfigApp(tester, neglectingConfig(router));
    await settleBrowser(tester);
    final start = browserSerialCount;

    unawaited(router.push(const PageRouteInfo<void>('Checkout')));
    await settleBrowser(tester);
    final onCheckout = (browserPath, browserSerialCount);
    unawaited(router.push(const PageRouteInfo<void>('Done')));
    await settleBrowser(tester);
    final onDone = (browserPath, browserSerialCount);
    await pressBrowserBack(tester);

    expect(onCheckout, ('/', start));
    expect(onDone, ('/done', start + 1));
    expect((browserPath, browserSerialCount), ('/', start));
    expectTopPage(router, 'Home');
  });
}
