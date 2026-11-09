import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// #844 (auto_route 3.x, repo naamapps/auto_route_bug): pushing the same page
// again from a nested router showed a blank page; after popping it, the next
// push worked.
// Setup: root 'HomeRoute' shell with children 'FirstRoute' (initial) and
// 'SecondRoute'. SecondRoute has a button 'Open Second Page Again' that pushes
// SecondRoute with context.router.
// Steps: from FirstRoute push SecondRoute; tap the button; pop; tap again.
// Should: each tap shows the second page (never blank), the nested stack grows
// by one each time, and a pop shows the page below.
void main() {
  testWidgets('Pushing the same nested page again shows it, not a blank one', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          initial: true,
          page: PageInfo('HomeRoute', builder: (_) => const AutoRouter()),
          children: [
            AutoRoute(
              path: 'first',
              initial: true,
              page: PageInfo(
                'FirstRoute',
                builder: (_) => const Text('First page'),
              ),
            ),
            AutoRoute(
              path: 'second',
              page: PageInfo(
                'SecondRoute',
                builder: (_) => Builder(
                  builder: (context) => Column(
                    children: [
                      const Text('Second page'),
                      ElevatedButton(
                        onPressed: () => unawaited(
                          context.router.push(const NamedRoute('SecondRoute')),
                        ),
                        child: const Text('Open Second Page Again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    final home = router.innerRouterOf<StackRouter>('HomeRoute')!;
    unawaited(home.push(const NamedRoute('SecondRoute')));
    await tester.pumpAndSettle();
    expect(find.text('Second page'), findsOneWidget);

    for (var round = 0; round < 2; round++) {
      await tester.tap(find.text('Open Second Page Again'));
      await tester.pumpAndSettle();
      expect(find.text('Second page'), findsOneWidget, reason: 'round $round');
      expect(home.stack.map((page) => page.name), [
        'FirstRoute',
        'SecondRoute',
        'SecondRoute',
      ]);
      home.pop();
      await tester.pumpAndSettle();
      expect(find.text('Second page'), findsOneWidget);
      expect(home.stack.map((page) => page.name), [
        'FirstRoute',
        'SecondRoute',
      ]);
    }
    expect(tester.takeException(), isNull);
  });
}
