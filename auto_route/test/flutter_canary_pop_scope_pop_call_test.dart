import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'back_test_utils.dart';

// Canary for Flutter bug https://github.com/flutter/flutter/issues/163052:
// PopScope can't replace WillPopScope where an app wants to hear only the
// user's back, since its callback also runs for a pop the app makes itself,
// with the same arguments.
// Setup, without auto_route: a page in a PopScope (canPop true) that records
// onPopInvokedWithResult.
// Steps: go back with the system back button; open the page again and close
// it with Navigator.pop().
// Today, on Flutter 3.47.9: both report (didPop: true, result: null), so the
// page can't tell them apart. Navigator.pop calls onPopInvokedWithResult
// with didPop true for every pop (flutter/lib/src/widgets/navigator.dart:
// 3372, `_RouteEntry.handlePop`), and maybePop, which the back button uses,
// ends in that same pop (navigator.dart:5605-5607). Flutter has no callback
// that runs only before a back the user asked for, as WillPopScope.onWillPop
// did.
// auto_route's router.pop() and router.maybePop() end in the same calls, and
// AutoRouteLeaveListener tells a pop from other leaves but not a back button
// from a pop call. If this test fails after a Flutter upgrade, Flutter now
// tells them apart: drop this canary.
void main() {
  testWidgets(
    'PopScope hears a pop call exactly as a system back, until Flutter fixes '
    'flutter/flutter#163052',
    (tester) async {
      final heard = <(bool, Object?)>[];
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          theme: androidTheme,
          home: const Text('home'),
        ),
      );
      Future<void> openPage() async {
        navigatorKey.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => PopScope(
              onPopInvokedWithResult: (didPop, result) =>
                  heard.add((didPop, result)),
              child: const Text('page'),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await openPage();
      await systemBack(tester);
      await openPage();
      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('page'), findsNothing);
      expect(heard, [(true, null), (true, null)]);
    },
  );
}
