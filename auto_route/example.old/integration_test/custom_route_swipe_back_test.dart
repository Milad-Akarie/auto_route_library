import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/page_kinds_router.dart';

// A CustomRoute with enableCupertinoBackGesture keeps the iOS back swipe.
// https://github.com/flutter/flutter/issues/183252, asked of go_router.
// Headless test: auto_route/test/transitions/custom_route_swipe_back_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: a CustomRoute with a fade transitionsBuilder and
  // enableCupertinoBackGesture: true; push it, then swipe from the left edge
  // of the screen.
  // Should: on iOS and macOS the swipe pops the page; elsewhere it does
  // nothing, as the option is for the iOS back swipe only.
  testWidgets('A back swipe pops a custom-transition page that opts in', (
    tester,
  ) async {
    final router = pageKindsRouter(
      customTransitionsBuilder: TransitionsBuilders.fadeIn,
      hasCustomCupertinoBackGesture: true,
    );
    await pumpRouterApp(tester, router);
    unawaited(router.push(const NamedRoute('CustomKindRoute')));
    await tester.pumpAndSettle();
    expectTopPage(router, 'CustomKindRoute');

    await swipeBack(tester);

    // In a browser, the platform is the computer's, so a Mac swipes too.
    final isSwipeBack =
        defaultTargetPlatform == .iOS || defaultTargetPlatform == .macOS;
    expect(
      router.stack.map((page) => page.name),
      isSwipeBack ? ['HomeRoute'] : ['HomeRoute', 'CustomKindRoute'],
    );
  });
}
