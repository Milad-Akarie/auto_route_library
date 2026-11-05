// Flutter's state restoration doesn't run on the web.
@TestOn('vm')
library;

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'restoration_test_utils.dart';

void main() {
  // Opens Home, List and Detail, then a note pushed with restorablePush, and
  // lets the platform end and restore the app.
  Future<void> openAndRestore(WidgetTester tester) async {
    await tester.pumpWidget(
      const RestorableRouterApp(_buildRouter, navRestorationScopeId: 'nav'),
    );
    await tester.pumpAndSettle();
    final router = RestorableRouterApp.router;
    unawaited(router.push(const NamedRoute('ListRoute')));
    await tester.pumpAndSettle();
    unawaited(router.push(const NamedRoute('DetailRoute')));
    await tester.pumpAndSettle();
    router.navigatorKey.currentState!.restorablePush(_noteRoute);
    await tester.pumpAndSettle();
    expect(find.text('note'), findsOneWidget);
    await tester.restartAndRestore();
  }

  // flutter/flutter#124946: a RangeError in NavigatorState._flushHistoryUpdates
  // during restoreState, tied in the thread to popUntil at app start with
  // routes pushed with restorablePush; no reproduction was given.
  // Steps: open Home, List, Detail and a restorablePush'd note, let the
  // platform end and restore the app, then pop until the first page after
  // the restored app's first frame.
  // Should: no error, and Home alone is left.
  testWidgets("popUntil the first page after a restored app's first frame", (
    tester,
  ) async {
    await openAndRestore(tester);
    final router = RestorableRouterApp.router;
    final restored = router.stack.map((p) => p.name).join(', ');
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => router.popUntil((route) => route.isFirst),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(
      (
        restored,
        tester.takeException(),
        router.stack.map((p) => p.name).join(', '),
        find.text('note').evaluate().length,
      ),
      ('HomeRoute, ListRoute, DetailRoute', null, 'HomeRoute', 0),
    );
  });

  // flutter/flutter#124946, popUntil before that frame, as the restored app
  // starts: the root navigator isn't built yet, so there is no route to pop.
  // Should: no error while the restored pages and the note come back.
  testWidgets("popUntil before a restored app's first frame throws nothing", (
    tester,
  ) async {
    await openAndRestore(tester);
    RestorableRouterApp.router.popUntil((route) => route.isFirst);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

RootStackRouter _buildRouter() => .build(
  routes: [
    for (final name in ['HomeRoute', 'ListRoute', 'DetailRoute'])
      AutoRoute(
        page: page(name),
        initial: name == 'HomeRoute',
        restorationId: (match) => match.name,
      ),
  ],
);

// A pageless route the navigator restores, pushed with restorablePush, which
// takes a static function.
@pragma('vm:entry-point')
Route<void> _noteRoute(BuildContext context, Object? arguments) =>
    MaterialPageRoute(builder: (_) => const Text('note'));
