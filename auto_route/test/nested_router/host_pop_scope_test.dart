import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../back_test_utils.dart';
import '../router_test_utils.dart';

// flutter/flutter#144074: a route with two PopScopes tells both of a pop
// either one blocks. A page hosting a nested AutoRouter has one PopScope
// from NavigatorPopHandler, which hands back to the nested router, so an
// app's own PopScope on that page could hear of back presses the nested
// router took.
// Steps: a host page wrapped in the app's PopScope(canPop: false), whose
// nested router has [A, B]; press back twice.
// Should: the first press pops B and the app's PopScope hears nothing; the
// second, with the nested router on its first page, is the app's PopScope's
// to block: it hears one refused pop and the host stays.
void main() {
  testWidgets("an app's PopScope on a host page hears only the back presses it blocks", (tester) async {
    final heard = <bool>[];
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('HomeRoute', builder: (_) => const Text('HomeRoute')),
        ),
        AutoRoute(
          path: '/host',
          page: PageInfo(
            'HostRoute',
            builder: (_) => PopScope<Object?>(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) => heard.add(didPop),
              child: const Scaffold(body: AutoRouter()),
            ),
          ),
          children: [
            AutoRoute(
              path: '',
              page: PageInfo('A', builder: (_) => const Text('A')),
            ),
            AutoRoute(
              path: 'b',
              page: PageInfo('B', builder: (_) => const Text('B')),
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    unawaited(router.pushPath('/host'));
    await tester.pumpAndSettle();
    final nested = router.innerRouterOf<StackRouter>('HostRoute')!;
    unawaited(nested.pushPath('b'));
    await tester.pumpAndSettle();

    await systemBack(tester);
    expect(nested.stack.map((page) => page.name), ['A']);
    expect(heard, isEmpty);

    await systemBack(tester);
    expect(heard, [false]);
    expect(router.stack.map((page) => page.name), ['HomeRoute', 'HostRoute']);
    expect(find.text('A'), findsOneWidget);
  });
}
