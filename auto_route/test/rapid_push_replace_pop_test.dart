import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'back_test_utils.dart';

// flutter/flutter#92030: tapping fast through push, replace and pop drew the
// last transition wrongly.
// Steps: on iOS, from P1 push P2, replace it with P3 50 ms later, and pop
// 50 ms after that, before any transition ends.
// Should: only P1 is left, it shows, and nothing throws.
void main() {
  testWidgets('push, replace and pop within a few frames leave the first page', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        for (final page in ['P1', 'P2', 'P3'])
          AutoRoute(
            path: page == 'P1' ? '/' : '/${page.toLowerCase()}',
            page: PageInfo(page, builder: (_) => Scaffold(body: Text(page))),
          ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(theme: iosTheme, routerConfig: router.config()));
    await tester.pumpAndSettle();

    unawaited(router.pushPath('/p2'));
    await tester.pump(const Duration(milliseconds: 50));
    unawaited(router.replacePath('/p3'));
    await tester.pump(const Duration(milliseconds: 50));
    router.pop();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(router.stack.map((page) => page.name), ['P1']);
    expect(find.text('P1'), findsOneWidget);
    expect(find.text('P2'), findsNothing);
    expect(find.text('P3'), findsNothing);
  });
}
