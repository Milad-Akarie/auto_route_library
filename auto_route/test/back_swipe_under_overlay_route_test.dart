import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'back_test_utils.dart';
import 'banner_route.dart';

// flutter/flutter#33875: on iOS, a back swipe on a page covered by a route
// that is not modal, such as a Flushbar's OverlayRoute, popped the top route
// instead and left the page stuck mid-swipe.
// Steps: on iOS, with the stack [P1, P2], push an OverlayRoute showing a
// banner over P2 on the router's navigator. Swipe from the left edge past
// the middle and let go.
// Should: nothing is popped, the banner stays, and P2 is back in place and
// takes taps. The swipe still drags P2 while it lasts, as in plain Flutter:
// flutter_canary_back_swipe_under_overlay_route_test.dart pins that.
void main() {
  testWidgets('a back swipe on a page under an overlay route pops nothing', (
    tester,
  ) async {
    var taps = 0;
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'P1',
          path: '/',
          builder: (_, _) => const Scaffold(body: Center(child: Text('P1'))),
        ),
        NamedRouteDef(
          name: 'P2',
          path: '/p2',
          builder: (_, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => taps++,
                child: const Text('P2'),
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: iosTheme, routerConfig: router.config()),
    );
    await tester.pumpAndSettle();
    unawaited(router.push(const NamedRoute('P2')));
    await tester.pumpAndSettle();
    final restingPlace = tester.getTopLeft(find.text('P2'));
    router.navigatorKey.currentState!.push(BannerRoute());
    await tester.pumpAndSettle();

    await swipeBack(tester);

    expect(tester.takeException(), isNull);
    expect(router.stack.map((page) => page.name), ['P1', 'P2']);
    expect(find.text('Banner'), findsOneWidget);
    expect(tester.getTopLeft(find.text('P2')), restingPlace);
    await tester.tap(find.text('P2'));
    expect(taps, 1);
  });
}
