import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'router_test_utils.dart';

// Fixed in d05951cc. A router told no one when one of its pages was popped:
// it only rebuilt the url, and only when the popped page was the active one.
// So a widget listening to the router, such as one showing the current page's
// name, kept showing the page that had left.
// Steps: listen to a router, push a page, pop it.
// Should: the router's listeners hear the pop.
void main() {
  testWidgets("a router's listeners hear a pop", (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: PageInfo('HomeRoute', builder: (_) => const Text('Home')),
          initial: true,
        ),
        AutoRoute(
          page: PageInfo('DetailRoute', builder: (_) => const Text('Detail')),
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    unawaited(router.push(const PageRouteInfo('DetailRoute')));
    await tester.pumpAndSettle();

    var heard = 0;
    void listener() => heard++;
    router.addListener(listener);
    addTearDown(() => router.removeListener(listener));

    await router.maybePop();
    await tester.pumpAndSettle();
    expect(router.current.name, 'HomeRoute');
    expect(heard, greaterThan(0));
  });
}
