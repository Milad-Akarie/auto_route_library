import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../back_test_utils.dart';
import '../router_test_utils.dart';

// flutter/flutter#131457, #132229.
// Steps: on page 1 raise a counter held in its State; push page 2 (and, for
// #132229, the same page 2 twice more); go back.
// Should: page 1 keeps its State and counter; each back removes one page.
void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('OneRoute', builder: (_) => const _Counter()),
        ),
        AutoRoute(
          path: '/two',
          page: PageInfo(
            'TwoRoute',
            builder: (_) => const Scaffold(body: Text('TwoRoute')),
          ),
        ),
      ],
    );
  });

  testWidgets('Page 1 keeps its state after going back from page 2', (
    tester,
  ) async {
    await pumpRouterApp(tester, router);
    await tester.tap(find.text('count 0'));
    await tester.pump();
    unawaited(router.push(const NamedRoute('TwoRoute')));
    await tester.pumpAndSettle();

    await systemBack(tester);
    expect(find.text('count 1'), findsOneWidget);
  });

  testWidgets('A page pushed three times goes back one page at a time', (
    tester,
  ) async {
    await pumpRouterApp(tester, router);
    for (var i = 0; i < 3; i++) {
      unawaited(router.push(const NamedRoute('TwoRoute')));
      await tester.pumpAndSettle();
    }
    expect(router.stack.length, 4);
    await systemBack(tester);
    expect(router.stack.length, 3);
    await systemBack(tester);
    await systemBack(tester);
    expect(router.stack.map((p) => p.name), ['OneRoute']);
  });
}

class _Counter extends StatefulWidget {
  const new();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: TextButton(
      onPressed: () => setState(() => count++),
      child: Text('count $count'),
    ),
  );
}
