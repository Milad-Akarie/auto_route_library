import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'back_test_utils.dart';
import 'router_test_utils.dart';

// Reported as https://github.com/Milad-Akarie/auto_route_library/issues/1853
// Setup: iOS, a home page and a CupertinoRoute page wrapped in
// PopScope(canPop: false).
// Steps: open the page, swipe back from the left edge, then press system
// back.
// Happened: the swipe popped the page although canPop was false (the
// reporter switched to MaterialRoute). A commenter says 7.9.0 fixed it.
// Should: the page stays and the PopScope hears each blocked back.
void main() {
  testWidgets('the iOS swipe does not pop a CupertinoRoute with canPop false', (
    tester,
  ) async {
    final heard = <bool>[];
    final router = RootStackRouter.build(
      routes: [
        CupertinoRoute(page: _page('Home', null), path: '/', initial: true),
        CupertinoRoute(page: _page('Guarded', heard), path: '/guarded'),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: iosTheme, routerConfig: router.config()),
    );
    await tester.pumpAndSettle();
    unawaited(router.push(const NamedRoute('Guarded')));
    await tester.pumpAndSettle();

    await swipeBack(tester);

    expectCurrentPage(router, 'Guarded');
    final poppedBySwipe = heard.where((didPop) => didPop).length;

    await systemBack(tester);

    expectCurrentPage(router, 'Guarded');
    expect((poppedBySwipe, heard.where((didPop) => didPop).length), (0, 0));
  });
}

PageInfo _page(String name, List<bool>? heard) => .new(
  name,
  builder: (_) => PopScope(
    canPop: heard == null,
    onPopInvokedWithResult: (didPop, _) => heard?.add(didPop),
    child: Scaffold(body: Text(name)),
  ),
);
