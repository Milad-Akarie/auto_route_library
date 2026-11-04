import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// flutter/flutter#142371: tapping the app bar's back button several times
// quickly, while the page was popping, asserted 'Future already completed'
// in debug mode.
// Steps: stack [P1, P2, P3], P3 with an AutoLeadingButton; tap the back
// button three times, 30 ms apart.
// Should: nothing throws. The first tap pops P3; the others land on P3
// while it leaves, which takes no taps, so P2 stays.
void main() {
  testWidgets('three quick taps on the back button pop one page without an error', (tester) async {
    Widget page(String name) => Scaffold(
      appBar: AppBar(leading: const AutoLeadingButton()),
      body: Text(name),
    );
    final router = RootStackRouter.build(
      routes: [
        for (final name in ['P1', 'P2', 'P3'])
          AutoRoute(
            path: name == 'P1' ? '/' : '/${name.toLowerCase()}',
            page: PageInfo(name, builder: (_) => page(name)),
          ),
      ],
    );
    await pumpRouterApp(tester, router);
    unawaited(router.pushPath('/p2'));
    await tester.pumpAndSettle();
    unawaited(router.pushPath('/p3'));
    await tester.pumpAndSettle();
    final backButton = tester.getCenter(find.byType(BackButton));

    for (var tap = 0; tap < 3; tap++) {
      await tester.tapAt(backButton);
      await tester.pump(const Duration(milliseconds: 30));
    }
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(router.stack.map((page) => page.name), ['P1', 'P2']);
    expect(find.text('P2'), findsOneWidget);
  });
}
