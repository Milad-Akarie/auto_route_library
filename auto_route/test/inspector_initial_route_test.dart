import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'main_router.dart';
import 'router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/1628
  // Turning on the widget inspector's select mode makes Flutter hand the
  // router its initial route again. Steps: open a page, push a second one,
  // then give the delegate the initial route path once more. The stack
  // should stay as it is; it used to rebuild from the initial route, which
  // popped the second page or failed with "args can not be null".
  testWidgets('The initial route handed over again leaves the stack as it is', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(page: FirstRoute.page, path: '/', initial: true),
        AutoRoute(page: SecondRoute.page, path: '/second'),
      ],
    );
    await pumpRouterApp(tester, router);
    unawaited(router.push(const SecondRoute()));
    await tester.pumpAndSettle();
    expectTopPage(router, SecondRoute.name);

    final delegate = router.delegate();
    addTearDown(delegate.dispose);
    final configuration = await router
        .defaultRouteParser()
        .parseRouteInformation(RouteInformation(uri: Uri.parse('/')));
    await delegate.setInitialRoutePath(configuration);
    await tester.pumpAndSettle();

    expect(router.stackData.map((data) => data.name), [
      FirstRoute.name,
      SecondRoute.name,
    ]);
    expectTopPage(router, SecondRoute.name);
  });
}
