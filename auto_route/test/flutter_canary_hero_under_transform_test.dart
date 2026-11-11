import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Canary for Flutter bugs https://github.com/flutter/flutter/issues/83653
// and https://github.com/flutter/flutter/issues/128657: a Hero under a
// Transform.scale changes size and layout as its flight starts or ends (text
// rewraps, an image relays out and stutters).
// Setup, without auto_route: a first page with a 200 x 100 Hero under
// Transform.scale(scale: 0.5); a second page with the same Hero, unscaled.
// Steps: push the second page and look at the first frame of the flight.
// Should: the flying Hero starts as the first page drew it, 200 x 100 laid
// out and scaled to half.
// Today, on Flutter 3.47.9: the flight starts from the transformed bounding
// box of the source Hero (flutter/lib/src/widgets/heroes.dart:501-508,
// `_HeroFlightManifest._boundingBoxFor`) and lays the shuttle out in that
// box with no transform (heroes.dart:572-597, `_HeroFlight._buildOverlay`),
// so it is laid out at 100 x 50: its content is laid out again at a size it
// never had on either page.
// auto_route pages fly Heroes through a plain Navigator and HeroController,
// so its apps see the same. If this test fails after a Flutter upgrade, the
// flight now keeps the transform: drop this canary.
void main() {
  testWidgets(
    'a Hero under Transform.scale flies laid out at its scaled size, until '
    'Flutter fixes flutter/flutter#83653 and #128657',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: Center(
            child: Transform.scale(
              scale: 0.5,
              child: const Hero(
                tag: 'box',
                child: SizedBox(
                  width: 200,
                  height: 100,
                  child: Text('first box'),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.text('first box')), const Size(200, 100));
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Align(
            alignment: Alignment.topLeft,
            child: Hero(
              tag: 'box',
              child: SizedBox(key: ValueKey('flying'), width: 200, height: 100),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(
        tester.getSize(find.byKey(const ValueKey('flying'))),
        within(distance: 0.01, from: const Size(100, 50)),
      );
      await tester.pumpAndSettle();
    },
  );
}
