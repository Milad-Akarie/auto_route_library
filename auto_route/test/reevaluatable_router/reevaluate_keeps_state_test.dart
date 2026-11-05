import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

class _Counter extends StatefulWidget {
  const new();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;

  @override
  Widget build(BuildContext context) =>
      TextButton(onPressed: () => setState(() => count++), child: Text('Home count $count'));
}

// flutter/flutter#153916: a redirect triggered by the router refreshing sent
// the first page back through its builder, and it lost its State.
// Steps: the home page counts a tap, DetailsRoute (guarded by a login flag)
// is pushed and the router reevaluates its guards twice: once with the login
// kept, once after the login is gone and the guard redirects to LoginRoute.
// Should: the home page keeps its State below, on every step.
void main() {
  testWidgets('Reevaluating guards keeps the State of a page below the guarded one (flutter/flutter#153916)', (
    tester,
  ) async {
    final loggedIn = ValueNotifier(true);
    addTearDown(loggedIn.dispose);
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('HomeRoute', builder: (_) => const _Counter()),
        ),
        AutoRoute(
          path: '/details',
          page: PageInfo('DetailsRoute', builder: (_) => const Text('DetailsRoute')),
          guards: [
            AutoRouteGuard.simple((resolver, _) {
              if (loggedIn.value) {
                resolver.next();
              } else {
                unawaited(resolver.redirectUntil(const NamedRoute('LoginRoute')));
              }
            }),
          ],
        ),
        AutoRoute(
          path: '/login',
          page: PageInfo('LoginRoute', builder: (_) => const Text('LoginRoute')),
        ),
      ],
    );
    await pumpRouterApp(tester, router, reevaluationNotifier: loggedIn);
    await tester.tap(find.text('Home count 0'));
    await tester.pump();
    unawaited(router.push(const NamedRoute('DetailsRoute')));
    await tester.pumpAndSettle();
    expect(find.text('DetailsRoute'), findsOneWidget);

    unawaited(router.reevaluateGuards());
    await tester.pumpAndSettle();
    expect(find.text('DetailsRoute'), findsOneWidget, reason: 'after router.reevaluateGuards())');

    loggedIn.value = false;
    await tester.pumpAndSettle();
    expect(find.text('LoginRoute'), findsOneWidget);
    expect(tester.takeException(), isNull);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('Home count 1'), findsOneWidget);
  });
}
