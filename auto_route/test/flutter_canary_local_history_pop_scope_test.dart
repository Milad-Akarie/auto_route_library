import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Canary for Flutter bug https://github.com/flutter/flutter/issues/155289: a
// pop that only removes a LocalHistoryEntry no longer reaches the route's
// PopScope (it did up to Flutter 3.22).
// Setup, as in the report, without auto_route: a page wrapped in a PopScope
// that records onPopInvokedWithResult, with a LocalHistoryEntry added (the
// report's "Show Rectangle").
// Steps: Navigator.pop() on the page.
// Today, on Flutter 3.47.9: the entry is removed and the PopScope hears
// nothing. `_RouteEntry.handlePop` returns as soon as `route.didPop` says the
// route stays (flutter/lib/src/widgets/navigator.dart:3368-3371), before the
// `onPopInvokedWithResult` call at line 3372; Flutter 3.22 called it in
// `_RouteEntry.pop` before asking the route. The change came with the page
// API rewrite (flutter/flutter#137792).
// An auto_route page takes local history entries the same way (auto_route
// doesn't touch them), and router.maybePop() ends in Navigator.pop. If this
// test fails after a Flutter upgrade, PopScope hears the removal again: drop
// this canary.
void main() {
  testWidgets(
    'popping a local history entry does not reach the PopScope, until '
    'Flutter fixes flutter/flutter#155289',
    (tester) async {
      final heard = <bool>[];
      final removed = <String>[];
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(navigatorKey: navigatorKey, home: const Text('home')),
      );
      late BuildContext pageContext;
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (context) {
            pageContext = context;
            return PopScope(
              onPopInvokedWithResult: (didPop, _) => heard.add(didPop),
              child: const Text('page'),
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      ModalRoute.of(pageContext)!.addLocalHistoryEntry(
        LocalHistoryEntry(onRemove: () => removed.add('rectangle')),
      );

      Navigator.of(pageContext).pop();
      await tester.pumpAndSettle();
      expect(removed, ['rectangle']);
      expect(find.text('page'), findsOneWidget);
      expect(heard, isEmpty);
    },
  );

  testWidgets('the same through router.maybePop() in an auto_route app', (
    tester,
  ) async {
    final heard = <bool>[];
    final removed = <String>[];
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: PageInfo('HomeRoute', builder: (_) => const Text('home')),
          path: '/',
        ),
        AutoRoute(
          page: PageInfo(
            'PageRoute',
            builder: (_) => PopScope(
              onPopInvokedWithResult: (didPop, _) => heard.add(didPop),
              child: const Text('page'),
            ),
          ),
          path: '/page',
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router.config()));
    await tester.pumpAndSettle();
    unawaited(router.navigatePath('/page'));
    await tester.pumpAndSettle();
    ModalRoute.of(tester.element(find.text('page')))!.addLocalHistoryEntry(
      LocalHistoryEntry(onRemove: () => removed.add('rectangle')),
    );

    final wasPopped = router.maybePop();
    await tester.pumpAndSettle();
    expect(await wasPopped, isTrue);
    expect(removed, ['rectangle']);
    expect(find.text('page'), findsOneWidget);
    expect(heard, isEmpty);
  });
}
