import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/1005
// "Bad state: Future already completed" in Route.didComplete, reached from
// popUntil, pushAndPopUntil, popUntilRouteWithName, popUntilRoot and
// popAndPushAll when they run again before the previous navigation settles.
// Each test is one of the setups from the issue and its comments; none should
// throw, and each should leave the stack the calls describe.
void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(routes: [
      AutoRoute(page: _page('MainRoute'), initial: true),
      AutoRoute(page: _page('ShoppingCartRoute')),
      AutoRoute(page: _page('OrderSummaryRoute')),
      AutoRoute(page: _page('PaymentTerminationRoute')),
      AutoRoute(page: _page('MyDeliveriesRoute')),
      AutoRoute(page: _page('SignInRoute')),
      AutoRoute(page: _page('VerifyRoute')),
      AutoRoute(page: _page('CustomStackFlow')),
      AutoRoute(page: _page('FirstRoute')),
      AutoRoute(page: _page('SecondRoute')),
    ]);
  });

  List<String?> stackNames() => router.stack.map((p) => p.name).toList();

  // A recovery link opens the app, which calls pushAndPopUntil(SignInRoute)
  // and, from a listener on that page, pushAndPopUntil(VerifyRoute) at once.
  // The second call removes SignInRoute too, though it has not shown yet (#1797).
  testWidgets('pushAndPopUntil twice in a row', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    router.push(const PageRouteInfo('ShoppingCartRoute'));
    await tester.pumpAndSettle();

    router.pushAndPopUntil(const PageRouteInfo('SignInRoute'), predicate: (_) => false);
    router.pushAndPopUntil(const PageRouteInfo('VerifyRoute'), predicate: (_) => false);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(stackNames(), ['VerifyRoute']);
  });

  // The user taps through two screens quickly, each tap calling pushAndPopUntil
  // while the previous page is still animating.
  testWidgets('pushAndPopUntil while the previous one animates', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    router.push(const PageRouteInfo('ShoppingCartRoute'));
    await tester.pumpAndSettle();

    router.pushAndPopUntil(const PageRouteInfo('SignInRoute'), predicate: (_) => false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    router.pushAndPopUntil(const PageRouteInfo('VerifyRoute'), predicate: (_) => false);
    await tester.pump(const Duration(milliseconds: 50));
    router.pushAndPopUntil(const PageRouteInfo('MainRoute'), predicate: (_) => false);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(stackNames(), ['MainRoute']);
  });

  // From the payment page, popUntilRouteWithName(MainRoute) then push
  // MyDeliveriesRoute; a pop to MainRoute runs again before the push settles.
  testWidgets('popUntilRouteWithName, push, then popUntilRouteWithName again', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    for (final name in ['ShoppingCartRoute', 'OrderSummaryRoute', 'PaymentTerminationRoute']) {
      router.push(PageRouteInfo(name));
      await tester.pumpAndSettle();
    }

    router.popUntilRouteWithName('MainRoute');
    unawaited(router.push(const PageRouteInfo('MyDeliveriesRoute')));
    await tester.pump(const Duration(milliseconds: 50));
    router.popUntilRouteWithName('MainRoute');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(stackNames(), ['MainRoute']);
  });

  // popUntilRoot runs twice while pushed pages are still animating in, as when
  // switching tabs quickly calls it on each tap.
  testWidgets('popUntilRoot twice while pages animate in', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    router.push(const PageRouteInfo('ShoppingCartRoute'));
    router.push(const PageRouteInfo('OrderSummaryRoute'));
    await tester.pump(const Duration(milliseconds: 10));

    router.popUntilRoot();
    router.popUntilRoot();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(stackNames(), ['MainRoute']);
  });

  // The linked demo app: a pushed page makes a 150ms request in initState,
  // then calls popAndPushAll([FirstRoute(), SecondRoute()]) while it is still
  // animating in.
  testWidgets('popAndPushAll while the page it pops animates in', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    router.push(const PageRouteInfo('CustomStackFlow'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    router.popAndPushAll(const [PageRouteInfo('FirstRoute'), PageRouteInfo('SecondRoute')]);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(stackNames(), ['MainRoute', 'FirstRoute', 'SecondRoute']);
  });
}

PageInfo _page(String name) => PageInfo(name, builder: (_) => Scaffold(appBar: AppBar(), body: Text(name)));
