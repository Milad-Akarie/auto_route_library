import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// Fixed in 44b2489d. The edge shadow a Cupertino page transition paints on
// its start edge is a Decoration that holds a list of colors. It compared the
// lists by identity, so two shadows with the same colors were never equal, and
// a rebuild repainted a shadow that had not changed.
// Steps: build two transitions that draw the edge shadow, as a linear one
// does, both halfway in, and read the decoration each puts on its page.
// Should: the two decorations are equal and share a hashCode. Halfway in, each
// shadow lerps its own new color list, so only a comparison by value finds
// them equal.
void main() {
  testWidgets('two edge shadows with the same colors compare equal', (
    tester,
  ) async {
    Widget transition(Key key) => CupertinoPageTransition(
      primaryRouteAnimation: const AlwaysStoppedAnimation(0.5),
      secondaryRouteAnimation: const AlwaysStoppedAnimation(0),
      linearTransition: true,
      child: SizedBox(key: key, width: 100, height: 100),
    );

    const first = Key('first');
    const second = Key('second');
    await tester.pumpWidget(
      Directionality(
        textDirection: .ltr,
        child: Column(children: [transition(first), transition(second)]),
      ),
    );

    Decoration shadowAbove(Key key) => tester
        .widget<DecoratedBox>(
          find.ancestor(
            of: find.byKey(key),
            matching: find.byType(DecoratedBox),
          ),
        )
        .decoration;

    final firstShadow = shadowAbove(first);
    final secondShadow = shadowAbove(second);
    expect(identical(firstShadow, secondShadow), isFalse);
    expect(firstShadow, secondShadow);
    expect(firstShadow.hashCode, secondShadow.hashCode);
  });
}
