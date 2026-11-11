import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Canary for Flutter bug https://github.com/flutter/flutter/issues/86089: a
// Hero that flies while its Navigator changes size has the wrong height
// until it lands, then jumps to its real size. The keyboard closing under a
// Scaffold that holds the Navigator is such a change.
// Setup, without auto_route: a Navigator with a HeroController in the body
// of a Scaffold, which resizes for the keyboard; on its pages a 100 x 50 Hero
// at the bottom; the keyboard is open, 300 px of view insets.
// Steps: push the second page, and let the keyboard close as the flight
// starts.
// Today, on Flutter 3.47.9: the flight places the shuttle with insets taken
// from the navigator's size when the flight started, so once the navigator
// grows the shuttle is 150 px tall instead of 50, and snaps back when it
// lands. The insets come from flutter/lib/src/widgets/heroes.dart:586-593,
// where `_HeroFlight._buildOverlay` uses `manifest.navigatorSize`.
// An auto_route router in a Scaffold body is that Navigator: a root router
// under a Scaffold from MaterialApp.router's builder, or a nested router
// given a HeroControllerScope. If this test fails after a Flutter upgrade,
// the flight now follows the navigator's size: drop this canary.
void main() {
  testWidgets(
    'a Hero flying while its navigator grows has the wrong height, until '
    'Flutter fixes flutter/flutter#86089',
    (tester) async {
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.reset);
      final heroes = HeroController();
      addTearDown(heroes.dispose);
      final navigatorKey = GlobalKey<NavigatorState>();
      Widget page({Key? boxKey}) => Column(
        children: [
          const Spacer(),
          Hero(
            tag: 'box',
            child: SizedBox(key: boxKey, width: 100, height: 50),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Navigator(
              key: navigatorKey,
              observers: [heroes],
              onGenerateRoute: (_) =>
                  MaterialPageRoute<void>(builder: (_) => page()),
            ),
          ),
        ),
      );
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => page(boxKey: const ValueKey('flying')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      tester.view.viewInsets = .zero;
      await tester.pump(const Duration(milliseconds: 100));
      final flying = find.byKey(const ValueKey('flying'));
      expect(tester.getSize(flying).height, moreOrLessEquals(150));

      await tester.pumpAndSettle();
      expect(tester.getSize(flying).height, moreOrLessEquals(50));
    },
  );
}
