import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// flutter/flutter#113365: Navigator.pop on the app's only page leaves a black
// screen and no error; the report proposes an error instead (an open Flutter
// proposal). auto_route's pop() is documented to pop "regardless if it's the
// last route", as Navigator.pop does; maybePop() is the call that keeps the
// last page (root_pop_test.dart).
// Steps: the root router shows only Home; call router.pop(), or
// Navigator.pop with the page's context.
// Should: as in Flutter, the page goes and nothing throws; the router shows
// its placeholder, the one given to config() (here 'Nothing to show'), by
// default a box in the theme's scaffold color rather than black. A push
// afterwards shows a page again.
void main() {
  final pops = <String, void Function(WidgetTester, StackRouter)>{
    'router.pop': (_, router) => router.pop(),
    'Navigator.pop': (tester, _) =>
        Navigator.pop(tester.element(find.text('Home'))),
  };

  for (final MapEntry(key: name, value: pop) in pops.entries) {
    testWidgets('$name on the only page shows the placeholder', (tester) async {
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            initial: true,
            builder: (_, _) => const Scaffold(body: Text('Home')),
          ),
        ],
      );
      await pumpRouterConfigApp(
        tester,
        router.config(placeholder: (_) => const Text('Nothing to show')),
      );

      pop(tester, router);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(router.stack, isEmpty);
      expect(find.text('Home'), findsNothing);
      expect(find.text('Nothing to show'), findsOneWidget);

      unawaited(router.push(const NamedRoute('HomeRoute')));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });
  }
}
