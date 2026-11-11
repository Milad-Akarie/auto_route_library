import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'banner_route.dart';

// Canary for Flutter bug https://github.com/flutter/flutter/issues/33875 (the
// iOS back swipe starts on a page covered by a route that is not modal, such
// as a Flushbar's OverlayRoute).
// Setup, as in the Flutter report, without auto_route: iOS, a home page, a
// second page pushed over it, and an OverlayRoute that shows a small banner
// pushed over that.
// Steps: swipe from the left edge past the middle, then let go.
// Today, on Flutter 3.47.9 with cupertino_ui 1.1.6: the swipe drags the
// covered second page off to the right, showing the home page, because
// ModalRoute.popGestureEnabled (flutter/lib/src/widgets/routes.dart) doesn't
// check isCurrent. On release, cupertino_ui's back gesture controller
// (lib/src/route.dart, dragEnd) sees the page is not current and slides it
// back: nothing is popped, the banner stays. The report's stuck screen and
// wrong pop no longer happen. If this test fails after a Flutter upgrade,
// Flutter changed the gesture on a covered page; auto_route's pages
// (auto_route_page.dart, popGestureEnabled) start from Flutter's answer and
// follow it, as back_swipe_under_overlay_route_test.dart checks.
void main() {
  testWidgets('a back swipe drags a page under an overlay route, then not', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: ThemeData(platform: .iOS),
        home: const Scaffold(body: Center(child: Text('P1'))),
      ),
    );
    navigator.currentState!
      ..push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Center(child: Text('P2'))),
        ),
      )
      ..push(BannerRoute());
    await tester.pumpAndSettle();
    final restingPlace = tester.getTopLeft(find.text('P2'));

    final swipe = await tester.startGesture(const Offset(2, 300));
    await swipe.moveBy(const Offset(200, 0));
    await tester.pump();
    await swipe.moveBy(const Offset(200, 0));
    await tester.pump();
    expect(tester.getTopLeft(find.text('P2')).dx, greaterThan(restingPlace.dx));
    expect(find.text('P1'), findsOneWidget);

    await swipe.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Banner'), findsOneWidget);
    expect(find.text('P1'), findsNothing);
    expect(tester.getTopLeft(find.text('P2')), restingPlace);
  });
}
