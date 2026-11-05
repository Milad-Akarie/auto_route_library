import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'back_test_utils.dart';

// Canary for Flutter bugs https://github.com/flutter/flutter/issues/24807
// and https://github.com/flutter/flutter/issues/142211: during an iOS swipe
// back, whatever a page paints outside its own box (a CustomPainter drawing
// past its size, a Transform.scale child in an AppBar's flexibleSpace) shows
// over the page beside it.
// Setup, without auto_route: iOS, a second page pushed with the Cupertino
// slide; on it, a box that paints wider than itself.
// Steps: start a swipe back from the left edge and hold it half way.
// Today, on Flutter 3.47.9 with cupertino_ui 1.1.6: CupertinoPageTransition
// slides the page with two SlideTransitions and no clip
// (cupertino_ui lib/src/route.dart:704-708), so nothing between the page and
// the navigator clips it. The workaround in both threads is a ClipRect around
// the page, which an app can put in its own page.
// auto_route's RouteType.cupertino pages (and adaptive pages on iOS and
// macOS) use the same transition. If this test fails after a Flutter upgrade,
// the transition now clips the page: drop this canary.
void main() {
  Finder clipsAbove(Finder content) => find.ancestor(
    of: content,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is ClipRect ||
          widget is ClipRRect ||
          widget is ClipPath ||
          widget is ClipOval,
    ),
  );

  final painted = find.byType(OverflowBox);

  // Holds a swipe back half way, checks the page that paints past its box
  // has no clip above it, then lets go.
  Future<void> expectUnclippedHalfWay(WidgetTester tester) async {
    final gesture = await tester.startGesture(const Offset(2, 300));
    await gesture.moveBy(const Offset(400, 0));
    await tester.pump();
    expect(find.text('first'), findsOneWidget);
    expect(clipsAbove(painted), findsNothing);
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets(
    'a page that paints past its box is not clipped during an iOS swipe '
    'back, until Flutter fixes flutter/flutter#24807 and #142211',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          theme: iosTheme,
          home: const Scaffold(body: Text('first')),
        ),
      );
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => _kOverflowingPage),
      );
      await tester.pumpAndSettle();
      await expectUnclippedHalfWay(tester);
    },
  );

  testWidgets('the same in an auto_route app with RouteType.cupertino', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      defaultRouteType: const RouteType.cupertino(),
      routes: [
        AutoRoute(
          page: PageInfo(
            'FirstRoute',
            builder: (_) => const Scaffold(body: Text('first')),
          ),
          path: '/',
        ),
        AutoRoute(
          page: PageInfo('OverflowRoute', builder: (_) => _kOverflowingPage),
          path: '/overflow',
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router.config()));
    await tester.pumpAndSettle();
    unawaited(router.navigatePath('/overflow'));
    await tester.pumpAndSettle();
    await expectUnclippedHalfWay(tester);
  });
}

// A page whose 100 px box paints 300 px wide, past both its edges, as a
// CustomPainter drawing past its size does.
const _kOverflowingPage = ColoredBox(
  color: Color(0xFFFFFFFF),
  child: Center(
    child: SizedBox(
      width: 100,
      height: 100,
      child: OverflowBox(
        maxWidth: 300,
        child: ColoredBox(
          color: Color(0xFFFF0000),
          child: SizedBox(width: 300, height: 100),
        ),
      ),
    ),
  ),
);
