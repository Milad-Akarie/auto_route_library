import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// Canary for Flutter issue https://github.com/flutter/flutter/issues/186187:
// one Navigator.pop() too many leaves a blank screen and no error.
// Setup: a MaterialApp with a home page, and the same in an auto_route app
// with two root routes.
// Steps: push a second page, then call Navigator.pop() twice.
// Today NavigatorState.pop removes the last route with no check and no
// message (widgets/navigator.dart, NavigatorState.pop), so the navigator is
// left empty. In auto_route the Navigator reports the page as removed and the
// router's stack becomes empty, so the router shows its placeholder. Flutter
// routes it as a proposal: an assertion or an error in debug builds.
// If this test fails after a Flutter upgrade, Flutter now refuses or reports
// the last pop: drop this canary and the note in the fork's Flutter list.
void main() {
  testWidgets('popping the only route empties a plain navigator silently', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigatorKey, home: const Text('Home')),
    );
    final navigator = navigatorKey.currentState!
      ..push(MaterialPageRoute<void>(builder: (_) => const Text('Two')));
    await tester.pumpAndSettle();
    navigator.pop();
    await tester.pumpAndSettle();
    navigator.pop();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Home'), findsNothing);
    expect(navigator.canPop(), isFalse);
  });

  testWidgets('popping the only page empties an auto_route stack silently', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('HomeRoute', builder: (_) => const Text('Home')),
        ),
        AutoRoute(
          path: '/two',
          page: PageInfo('TwoRoute', builder: (_) => const Text('Two')),
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    unawaited(router.pushPath('/two'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('Two'))).pop();
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('Home'))).pop();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Home'), findsNothing);
    expect(router.stack, isEmpty);
  });
}
