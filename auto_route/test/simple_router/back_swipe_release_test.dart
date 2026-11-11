import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../back_test_utils.dart';
import '../router_test_utils.dart';

// flutter/flutter#167859: on iOS, a back swipe let go past the middle of the
// screen glitched: the page jumped instead of sliding out from where the
// finger left it.
// The reporter's steps: from Home, open Details; swipe back from the left
// edge past the middle, stop, and let go. Details should slide out from where
// it was let go, smoothly, and Home show.
void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('Home'), initial: true),
        AutoRoute(page: _page('Details')),
      ],
    );
  });

  testWidgets(
    'a back swipe let go past the middle slides the page out from there',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(.resumed);
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: iosTheme, routerConfig: router.config()),
      );
      await tester.pumpAndSettle();
      unawaited(router.push(const PageRouteInfo('Details')));
      await tester.pumpAndSettle();
      final animation = router.topRoute.animation!;
      final width = tester.getSize(find.byType(Navigator).first).width;

      final gesture = await tester.startGesture(const Offset(2, 300));
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      await gesture.moveBy(Offset(width * 0.6 - 22, 0));
      await tester.pump();
      // Stop before letting go, so the release has no speed.
      await tester.pump(const Duration(milliseconds: 500));
      final atRelease = animation.value;
      expect(atRelease, closeTo(0.4, 0.05));
      await gesture.up();

      // Each frame, the page moves on toward the left edge: no jump back in,
      // and no jump straight out.
      final values = [atRelease];
      for (var frame = 0; frame < 60 && animation.value > 0; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        values.add(animation.value);
      }
      final [first, ...rest] = values;
      var previous = first;
      for (final (index, value) in rest.indexed) {
        expect(
          value,
          lessThanOrEqualTo(previous),
          reason: 'frame ${index + 1} of $values',
        );
        expect(
          previous - value,
          lessThan(0.2),
          reason: 'frame ${index + 1} of $values',
        );
        previous = value;
      }
      expect(values.lastOrNull, 0);

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(router.stack.map((page) => page.routeData.name), ['Home']);
      expectTopPage(router, 'Home');
    },
  );
}

PageInfo _page(String name) => .new(
  name,
  builder: (_) => Scaffold(
    appBar: AppBar(title: Text('$name bar')),
    body: Text(name),
  ),
);
