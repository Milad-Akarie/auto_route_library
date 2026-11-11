import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Canary for Flutter proposal https://github.com/flutter/flutter/issues/45542:
// the iOS back swipe takes a stylus (an Apple Pencil) like a finger; the
// proposal says iOS ignores the Pencil for navigation gestures, which the
// thread never confirmed.
// Setup, without auto_route: iOS, a second page pushed with the Cupertino
// slide.
// Steps: drag a stylus from the left edge across the screen.
// Today, on Flutter 3.47.9 with cupertino_ui 1.1.6: the page pops. The edge
// Listener hands every pointer to a HorizontalDragGestureRecognizer with no
// supportedDevices (cupertino_ui lib/src/route.dart:749 and 831-836,
// `_CupertinoBackGestureDetectorState`).
// auto_route's RouteType.cupertino pages use the same back gesture. If this
// test fails after a Flutter upgrade, the swipe now ignores a stylus: drop
// this canary.
void main() {
  testWidgets(
    'a stylus swipe from the left edge pops an iOS page, until Flutter '
    'decides flutter/flutter#45542',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          theme: ThemeData(platform: .iOS),
          home: const Scaffold(body: Text('first')),
        ),
      );
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('second')),
        ),
      );
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(
        const Offset(2, 300),
        kind: .stylus,
      );
      await gesture.moveBy(const Offset(500, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('second'), findsNothing);
      expect(find.text('first'), findsOneWidget);
    },
  );
}
