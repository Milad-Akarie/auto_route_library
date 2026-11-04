import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// flutter/flutter#142394: a pop followed in the same frame by a refresh of
// the router put the popped page back.
// Steps: a guarded stack [A, B] with a reevaluation listenable; call pop()
// and notify the listenable in the same tick. B should stay popped.
void main() {
  testWidgets('a guard reevaluation in the frame of a pop keeps the page popped', (tester) async {
    final reevaluate = ChangeNotifier();
    addTearDown(reevaluate.dispose);
    final router = RootStackRouter.build(
      guards: [AutoRouteGuardCallback((resolver, _) => resolver.next())],
      routes: [
        AutoRoute(page: _page('A'), initial: true),
        AutoRoute(page: _page('B')),
      ],
    );
    await pumpRouterApp(tester, router, reevaluationNotifier: reevaluate);
    unawaited(router.push(const PageRouteInfo('B')));
    await tester.pumpAndSettle();

    router.pop();
    reevaluate.notifyListeners();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(router.stack.map((page) => page.routeData.name), ['A']);
    expectTopPage(router, 'A');
  });
}

PageInfo _page(String name) => .new(name, builder: (_) => Scaffold(body: Text(name)));
