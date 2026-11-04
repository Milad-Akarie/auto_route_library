import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';
import 'disposal_tracker.dart';

void main() {
  // Steps: push HostRoute, whose page holds an AutoRouter.declarative, then
  // pop it.
  // Happened: the HeroController the declarative router creates stayed
  // undisposed, one more on each visit.
  // Should: popping the host disposes it.
  testWidgets('Popping a declarative router disposes its HeroController', (tester) async {
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
            builder: (_) => AutoRouter.declarative(routes: (_) => [const NamedRoute('ChildRoute')]),
          ),
          children: [
            AutoRoute(
              path: '',
              page: PageInfo('ChildRoute', builder: (_) => const Text('ChildRoute')),
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    // Started after the app, whose own HeroController lives until it closes.
    final heroControllers = DisposalTracker<HeroController>();
    unawaited(router.pushPath('/host'));
    await tester.pumpAndSettle();
    expect(find.text('ChildRoute'), findsOneWidget);
    expect(heroControllers.created, 1);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('HomeRoute'), findsOneWidget);
    expect(heroControllers.undisposed, 0);
  });
}
