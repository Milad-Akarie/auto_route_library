import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/187326
  // In go_router, two pops of the same page in one frame, as the iOS back
  // swipe can send, completed its push future twice and threw "Future already
  // completed".
  // Steps: push FirstRoute, SecondRoute and ThirdRoute; in one frame pop
  // ThirdRoute with Navigator.pop('swipe') and report its pop again with
  // onPopInvoked('again').
  // Should: no error, ThirdRoute's push future completes once with
  // 'swipe', and only ThirdRoute closes.
  testWidgets(
    'Two pops of the same page in one frame complete its push future once (flutter/flutter#187326)',
    (tester) async {
      Widget page(String name) => Scaffold(body: Text(name));
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            builder: (_, _) => page('HomeRoute'),
          ),
          NamedRouteDef(
            name: 'FirstRoute',
            path: '/first',
            builder: (_, _) => page('FirstRoute'),
          ),
          NamedRouteDef(
            name: 'SecondRoute',
            path: '/second',
            builder: (_, _) => page('SecondRoute'),
          ),
          NamedRouteDef(
            name: 'ThirdRoute',
            path: '/third',
            builder: (_, _) => page('ThirdRoute'),
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      unawaited(router.push(const NamedRoute('FirstRoute')));
      unawaited(router.push(const NamedRoute('SecondRoute')));
      final results = <String?>[];
      unawaited(
        router.push<String>(const NamedRoute('ThirdRoute')).then(results.add),
      );
      await tester.pumpAndSettle();
      final third = router.topPage!.routeData;

      Navigator.of(tester.element(find.text('ThirdRoute'))).pop('swipe');
      third.onPopInvoked('again');
      await tester.pumpAndSettle();
      third.onPopInvoked('later');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(results, ['swipe']);
      expect(router.stack.map((e) => e.routeData.name), [
        'HomeRoute',
        'FirstRoute',
        'SecondRoute',
      ]);
    },
  );
}
