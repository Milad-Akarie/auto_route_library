import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// Issue 1611, seen with auto_route 6 and 7: in a nested router, pushing the
// same detail page several times replaced the page, so one pop went back to
// the home page instead of detail A. A commenter links it to a listenable that
// reevaluates the guards.
// Setup: the root path is a shell route called HomeShellRoute. It has two
// children, HomeRoute (initial) and DetailRoute, a guarded page with a string
// argument.
// Steps: push DetailRoute with A, then with B, on the nested router, and pop
// once. Repeat with the guards reevaluated after each push.
// Should: the nested stack is Home, Detail A, Detail B; the pop shows Detail
// A, and the next one shows Home.
void main() {
  for (final reevaluates in [false, true]) {
    testWidgets('Pushing DetailRoute twice in a nested router stacks it '
        '(guards reevaluated after each push: $reevaluates)', (tester) async {
      final reevaluation = ValueNotifier(0);
      addTearDown(reevaluation.dispose);
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            initial: true,
            page: PageInfo(
              'HomeShellRoute',
              builder: (_) => const AutoRouter(),
            ),
            children: [
              AutoRoute(path: 'home', initial: true, page: _page('HomeRoute')),
              AutoRoute(
                path: 'detail',
                guards: [
                  AutoRouteGuard.simple((resolver, _) => resolver.next()),
                ],
                page: PageInfo(
                  'DetailRoute',
                  builder: (data) =>
                      Scaffold(body: Text('Detail ${data.argsAs<String>()}')),
                ),
              ),
            ],
          ),
        ],
      );
      await pumpRouterApp(
        tester,
        router,
        reevaluationNotifier: reevaluates ? reevaluation : null,
      );
      final shell = router.innerRouterOf<StackRouter>('HomeShellRoute')!;

      for (final letter in ['A', 'B']) {
        unawaited(shell.push(NamedRoute('DetailRoute', args: letter)));
        await tester.pumpAndSettle();
        if (reevaluates) {
          reevaluation.value++;
          await tester.pumpAndSettle();
        }
      }
      expect(tester.takeException(), isNull);
      expect(shell.stack.map((page) => page.name), [
        'HomeRoute',
        'DetailRoute',
        'DetailRoute',
      ]);
      expect(find.text('Detail B'), findsOneWidget);

      shell.pop();
      await tester.pumpAndSettle();
      expect(find.text('Detail A'), findsOneWidget);

      shell.pop();
      await tester.pumpAndSettle();
      expectTopPage(router, 'HomeRoute');
    });
  }
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));
