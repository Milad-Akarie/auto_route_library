import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// flutter/flutter#117453: pushing a path no route matches replaced the whole
// stack with the error page, so back could not return.
// Steps: open Home, then Details; push '/nope'. With a wildcard route, the
// unknown page goes on top and back returns to Details, then Home. Without
// one, the push reports RouteNotFoundFailure, or throws, and the stack stays.
void main() {
  List<String> names(StackRouter router) =>
      router.stack.map((page) => page.routeData.name).toList();

  Future<RootStackRouter> openDetails(
    WidgetTester tester, {
    required bool withWildcard,
  }) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('Home'), path: '/', initial: true),
        AutoRoute(page: _page('Details'), path: '/details'),
        if (withWildcard) AutoRoute(page: _page('Unknown'), path: '*'),
      ],
    );
    await pumpRouterApp(tester, router);
    unawaited(router.pushPath('/details'));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets(
    'with a wildcard route, the unknown page goes on top and back returns',
    (tester) async {
      final router = await openDetails(tester, withWildcard: true);

      unawaited(router.pushPath('/nope'));
      await tester.pumpAndSettle();
      expect(names(router), ['Home', 'Details', 'Unknown']);
      expectTopPage(router, 'Unknown');

      router.pop();
      await tester.pumpAndSettle();
      expectTopPage(router, 'Details');
      router.pop();
      await tester.pumpAndSettle();
      expectTopPage(router, 'Home');
    },
  );

  testWidgets(
    'without one, onFailure hears RouteNotFoundFailure and the stack stays',
    (tester) async {
      final router = await openDetails(tester, withWildcard: false);
      final failures = <NavigationFailure>[];

      unawaited(router.pushPath('/nope', onFailure: failures.add));
      await tester.pumpAndSettle();

      expect(failures.singleOrNull, isA<RouteNotFoundFailure>());
      expect(names(router), ['Home', 'Details']);
      expectTopPage(router, 'Details');
    },
  );

  testWidgets('without one or onFailure, the push throws and the stack stays', (
    tester,
  ) async {
    final router = await openDetails(tester, withWildcard: false);

    expect(() => router.pushPath('/nope'), throwsFlutterError);
    await tester.pumpAndSettle();

    expect(names(router), ['Home', 'Details']);
    expectTopPage(router, 'Details');
  });
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));
