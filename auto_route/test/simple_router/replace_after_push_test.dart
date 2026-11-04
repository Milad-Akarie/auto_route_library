import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// flutter/flutter#111356: after a page was pushed, replacing it with itself
// played a page transition.
// Steps: push DayRoute(1), then replace it with DayRoute(2).
// Should: the page updates in place: same page, no second page in the tree,
// no transition.
void main() {
  testWidgets('Replacing a pushed page with itself updates it in place', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(name: 'HomeRoute', path: '/', initial: true, builder: (_, _) => const Text('home')),
        NamedRouteDef(
          name: 'DayRoute',
          path: '/day/:id',
          builder: (_, data) => Text('day ${data.params.getString('id')}'),
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.push(const NamedRoute('DayRoute', params: {'id': '1'})));
    await tester.pumpAndSettle();
    expect(find.text('day 1'), findsOneWidget);
    final pageBefore = router.stack.last;

    unawaited(router.replace(const NamedRoute('DayRoute', params: {'id': '2'})));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // Mid-transition both pages would be built.
    expect(find.text('day 1'), findsNothing);
    expect(find.text('day 2'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(router.stack.map((p) => p.name), ['HomeRoute', 'DayRoute']);
    expect(router.stack.last.routeKey, pageBefore.routeKey);
    expect(router.currentUrl, '/day/2');
  });
}
