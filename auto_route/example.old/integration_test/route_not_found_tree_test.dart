import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/route_tree_router.dart';

// A navigation to a path no route matches reports the path and lists the
// app's routes as a tree, by full path.
// https://github.com/Milad-Akarie/auto_route_library/issues/338, and in
// go_router flutter/flutter#120382 and flutter/flutter#127957.
// Headless test: auto_route/test/route_not_found_tree_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: open '/shop/1/reviews', which no route matches, with onFailure.
  // Should: the failure names the path and lists the tree; the page stays.
  testWidgets('an unknown path reports the path and the route tree', (
    tester,
  ) async {
    final router = buildRouteTreeRouter();
    await pumpRouterApp(tester, router);
    final failures = <NavigationFailure>[];

    unawaited(router.pushPath('/shop/1/reviews', onFailure: failures.add));
    await tester.pumpAndSettle();

    expect(
      (failures.single as RouteNotFoundFailure).toString(),
      allOf(
        contains('Can not navigate to /shop/1/reviews'),
        contains(kRouteTreeOfRouteTreeRouter),
      ),
    );
    expect(router.current.name, 'HomeRoute');
    expect(find.text('Home'), findsOneWidget);
  });
}
