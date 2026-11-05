import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

import 'neglect_when_router.dart';
import 'router_test_utils.dart';

// Pins the README section "Keeping a url out of the address bar", under
// Working with Paths. When `neglectWhen` returns true for a url, the page
// still opens, but the url isn't reported, so the address bar keeps the url
// before it and no history entry is added.
// Steps: with an app whose config neglects urls under '/checkout', push
// Checkout, then Done.
// What shows without a browser is checked here: Checkout opens while the url
// the router last reported stays '/', and Done is reported. The browser
// history itself, where back then skips Checkout, needs Chrome, so it is
// checked by the neglectWhen test in the web folder.
void main() {
  testWidgets('A neglected url opens its page but keeps the url before it', (
    tester,
  ) async {
    final router = neglectingRouter();
    await pumpRouterConfigApp(tester, neglectingConfig(router));
    final provider = router.routeInfoProvider();

    unawaited(router.push(const PageRouteInfo<void>('Checkout')));
    await tester.pumpAndSettle();
    final onCheckout = (
      find.text('Checkout').evaluate().length,
      provider.value.uri.path,
    );
    unawaited(router.push(const PageRouteInfo<void>('Done')));
    await tester.pumpAndSettle();

    expect(onCheckout, (1, '/'));
    expect(provider.value.uri.path, '/done');
    expectTopPage(router, 'Done');
  });
}
