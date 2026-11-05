import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Canary for Flutter bug https://github.com/flutter/flutter/issues/119882: on
// macOS a two-finger trackpad swipe does not go back, as it does in native
// macOS apps.
// Setup, without auto_route: macOS, a second page pushed with the Cupertino
// slide (Flutter's default page transition on macOS).
// Steps: with the cursor in the middle of the page, swipe right with two
// fingers on the trackpad.
// Today, on Flutter 3.47.9 with cupertino_ui 1.1.6: nothing happens. The
// back gesture starts only from a pointer down inside the 20 px strip at the
// left edge (cupertino_ui lib/src/route.dart:820-836,
// `_CupertinoBackGestureDetectorState.build`), and a trackpad swipe is a
// pan-zoom event at the cursor, with no pointer down there.
// auto_route's pages on macOS (RouteType.cupertino, adaptive and material
// pages under Flutter's default macOS theme) use the same transition. If this
// test fails after a Flutter upgrade, the swipe now goes back: drop this
// canary.
void main() {
  testWidgets(
    'a two-finger trackpad swipe on macOS does not go back, until Flutter '
    'fixes flutter/flutter#119882',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          theme: ThemeData(platform: .macOS),
          home: const Scaffold(body: Text('first')),
        ),
      );
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Center(child: Text('second'))),
        ),
      );
      await tester.pumpAndSettle();
      await tester.trackpadFling(
        find.text('second'),
        const Offset(600, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.text('second'), findsOneWidget);
      expect(navigatorKey.currentState!.canPop(), isTrue);
    },
  );
}
