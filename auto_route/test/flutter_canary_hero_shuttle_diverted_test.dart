import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Canary for Flutter bug https://github.com/flutter/flutter/issues/53523: a
// Hero flight's flightShuttleBuilder animation never completes when a pop
// flight is turned around by a new push.
// Setup, as in the report, without auto_route: a list page and a details
// page with Heroes of the same tag, both with a flightShuttleBuilder that
// listens to the animation it is given.
// Steps: open the details page, go back, and open it again before the
// back flight ends.
// Should: the animation the shuttle listens to completes when the hero lands
// on the details page again.
// Today, on Flutter 3.47.9: the shuttle is built once per flight with the
// route animation of that flight (flutter/lib/src/widgets/heroes.dart:
// 572-579, `_HeroFlight._buildOverlay`); when the push turns the pop flight
// around, `_HeroFlight.divert` (heroes.dart:759-779) keeps that shuttle, so
// it still listens to the popped route's animation, which ends dismissed.
// auto_route pages fly Heroes through a plain Navigator and HeroController,
// so its apps see the same. If this test fails after a Flutter upgrade, the
// shuttle now hears the new flight: drop this canary.
void main() {
  testWidgets(
    'a shuttle of a pop flight turned around by a push never sees its '
    'animation complete, until Flutter fixes flutter/flutter#53523',
    (tester) async {
      final shuttles = <List<AnimationStatus>>[];
      Widget hero(double size) => Hero(
        tag: 'box',
        flightShuttleBuilder: (_, animation, _, _, toHeroContext) {
          final statuses = <AnimationStatus>[];
          shuttles.add(statuses);
          animation.addStatusListener(statuses.add);
          return (toHeroContext.widget as Hero).child;
        },
        child: SizedBox(width: size, height: size),
      );
      final navigatorKey = GlobalKey<NavigatorState>();
      void openDetails() => navigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) =>
              Align(alignment: Alignment.bottomRight, child: hero(200)),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: Align(alignment: Alignment.topLeft, child: hero(50)),
        ),
      );
      openDetails();
      await tester.pumpAndSettle();
      navigatorKey.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      openDetails();
      await tester.pumpAndSettle();

      // The first push's shuttle saw its flight land; the shuttle of the
      // back flight, kept for the second push, never does.
      final [pushShuttle, backShuttle] = shuttles;
      expect(pushShuttle, contains(AnimationStatus.completed));
      expect(
        backShuttle,
        allOf(
          isNot(contains(AnimationStatus.completed)),
          contains(AnimationStatus.dismissed),
        ),
      );
    },
  );
}
