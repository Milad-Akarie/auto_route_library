import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Canary for Flutter bug https://github.com/flutter/flutter/issues/4770, its
// third case: a navigation cancels a gesture outside the navigator.
// Setup, without auto_route: a long press detector wraps the app's
// Navigator, as an app-wide gesture (a debug overlay, a three-finger
// gesture) does.
// Steps: put a finger down on the page, let something else push a page
// 100 ms later (a timer, a notification), keep holding until the long press
// timeout passes.
// Should: the long press above the navigator still fires, since it belongs
// to no route.
// Today, on Flutter 3.47.9: every navigation cancels the pointers that are
// down on the navigator, for every recognizer in the app, so the outer long
// press never fires. The cancel is in flutter/lib/src/widgets/navigator.dart
// at lines 5908-5922 (`NavigatorState._cancelActivePointers`, which calls
// `GestureBinding.cancelPointer`).
// auto_route cancels the same way when the top page changes, in
// auto_route_navigator.dart (`_handleStackChanged`), as Flutter's Navigator
// does for push and pop, so its apps see it too. If this test fails after
// a Flutter upgrade, Flutter now cancels only the route's own gestures:
// make auto_route follow it, and drop this canary.
void main() {
  Future<int> holdOnPage(WidgetTester tester, {required bool isPushing}) async {
    var longPresses = 0;
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        builder: (context, navigator) =>
            GestureDetector(onLongPress: () => longPresses++, child: navigator),
        home: const Scaffold(body: Center(child: Text('first'))),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('first')),
    );
    await tester.pump(const Duration(milliseconds: 100));
    if (isPushing) {
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const Text('second')),
      );
    }
    await tester.pump(const Duration(milliseconds: 700));
    await gesture.up();
    await tester.pumpAndSettle();
    return longPresses;
  }

  testWidgets(
    'a push cancels a long press held on a detector above the navigator, '
    'until Flutter fixes flutter/flutter#4770',
    (tester) async {
      expect(await holdOnPage(tester, isPushing: true), 0);
    },
  );

  testWidgets('the control: without the push, the long press fires', (
    tester,
  ) async {
    expect(await holdOnPage(tester, isPushing: false), 1);
  });
}
