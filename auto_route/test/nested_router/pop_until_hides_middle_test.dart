import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// flutter/flutter#59990: Navigator.popUntil on a nested navigator under a
// bottom bar showed every page in between while it popped, one after the
// other.
// Steps: a host page with a nested router, whose stack is [A, B, C]; call
// popUntil for A on the nested router and watch every frame of the pop.
// Should: only C animates out, over A; B never shows, and B's push
// completes as a pop would complete it.
void main() {
  testWidgets('popUntil on a nested router never shows the pages in between', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'HostRoute',
            builder: (_) => const Scaffold(body: AutoRouter()),
          ),
          children: [
            for (final name in ['A', 'B', 'C'])
              AutoRoute(
                path: name == 'A' ? '' : name.toLowerCase(),
                page: PageInfo(name, builder: (_) => Text(name)),
              ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    final nested = router.innerRouterOf<StackRouter>('HostRoute')!;
    var isBClosed = false;
    unawaited(nested.pushPath('b').then((_) => isBClosed = true));
    await tester.pumpAndSettle();
    unawaited(nested.pushPath('c'));
    await tester.pumpAndSettle();
    expect(nested.stack.map((page) => page.name), ['A', 'B', 'C']);

    nested.popUntil((route) => route.settings.name == 'A');
    final shown = <String>{};
    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      for (final name in ['A', 'B', 'C']) {
        if (find.text(name).evaluate().isNotEmpty) shown.add(name);
      }
    }
    await tester.pumpAndSettle();

    expect(shown, {'A', 'C'});
    expect(isBClosed, isTrue);
    expect(nested.stack.map((page) => page.name), ['A']);
    expect(find.text('A'), findsOneWidget);
  });
}
