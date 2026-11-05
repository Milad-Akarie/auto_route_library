import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Canary for Flutter proposal https://github.com/flutter/flutter/issues/29807:
// a Hero's createRectTween is used only when that Hero is the one flown to,
// never when the flight starts from it.
// Setup, without auto_route: a first page with a Hero that sets
// createRectTween, a second page with a Hero of the same tag that sets none.
// Steps: push the second page.
// Today, on Flutter 3.47.9: the flight takes the destination Hero's tween or
// the HeroController's (flutter/lib/src/widgets/heroes.dart:495,
// `_HeroFlightManifest.createHeroRectTween`), so the first page's tween is
// never called; each destination page has to repeat it.
// auto_route pages fly Heroes through a plain Navigator and HeroController,
// so its apps see the same. If this test fails after a Flutter upgrade,
// Flutter now falls back to the source Hero's tween: drop this canary.
void main() {
  testWidgets(
    "the source Hero's createRectTween is not used, until Flutter takes up "
    'flutter/flutter#29807',
    (tester) async {
      final fromTweens = ValueNotifier(0);
      addTearDown(fromTweens.dispose);
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: Hero(
            tag: 'box',
            createRectTween: (begin, end) {
              fromTweens.value++;
              return RectTween(begin: begin, end: end);
            },
            child: const SizedBox(width: 50, height: 50),
          ),
        ),
      );
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Align(
            alignment: Alignment.bottomRight,
            child: Hero(tag: 'box', child: SizedBox(width: 100, height: 100)),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(Hero), findsNWidgets(2));
      await tester.pumpAndSettle();
      expect(fromTweens.value, 0);
    },
  );
}
