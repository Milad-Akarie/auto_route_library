import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../back_test_utils.dart';

RootStackRouter _router({
  required bool enableCupertinoBackGesture,
  bool fullscreenDialog = false,
}) {
  return RootStackRouter.build(
    routes: [
      AutoRoute(
        path: '/',
        page: PageInfo(
          'HomeRoute',
          builder: (_) => const Scaffold(body: Text('HomeRoute')),
        ),
      ),
      CustomRoute(
        path: '/details',
        page: PageInfo(
          'DetailsRoute',
          builder: (_) => const Scaffold(body: Text('DetailsRoute')),
        ),
        transitionsBuilder: TransitionsBuilders.fadeIn,
        fullscreenDialog: fullscreenDialog,
        enableCupertinoBackGesture: enableCupertinoBackGesture,
      ),
    ],
  );
}

Future<void> _pumpAtDetails(WidgetTester tester, RootStackRouter router) async {
  addTearDown(router.dispose);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router.config()));
  await tester.pumpAndSettle();
  unawaited(router.pushPath('/details'));
  await tester.pumpAndSettle();
}

void main() {
  // https://github.com/flutter/flutter/issues/183252, asked of go_router.
  // Asked: a page with a custom transition, such as a fade, keeps the iOS
  // back swipe from the screen's left edge, as an option.
  // Steps: a CustomRoute with a fade transitionsBuilder and
  // enableCupertinoBackGesture: true; push it, then swipe from the left edge.
  // Should: the page follows the finger through its own fade, and the swipe
  // pops it.
  testWidgets(
    'A custom-transition page with enableCupertinoBackGesture pops on a back '
    'swipe',
    (tester) async {
      final router = _router(enableCupertinoBackGesture: true);
      await _pumpAtDetails(tester, router);

      // Halfway through the swipe, the page's own fade follows the finger.
      final gesture = await tester.startGesture(const Offset(5, 300));
      await gesture.moveBy(const Offset(400, 0));
      await tester.pump();
      final fade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.text('DetailsRoute'),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(fade.opacity.value, closeTo(0.5, 0.01));
      // The page itself doesn't slide: only its own transition shows.
      expect(tester.getTopLeft(find.text('DetailsRoute')).dx, 0);
      await gesture.moveBy(const Offset(300, 0));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(router.stack.map((page) => page.name), ['HomeRoute']);
      expect(find.text('DetailsRoute'), findsNothing);
    },
    variant: const TargetPlatformVariant({.iOS, .macOS}),
  );

  testWidgets(
    'A back swipe that is let go early brings the custom-transition page back',
    (tester) async {
      final router = _router(enableCupertinoBackGesture: true);
      await _pumpAtDetails(tester, router);

      final gesture = await tester.startGesture(const Offset(5, 300));
      await gesture.moveBy(const Offset(100, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(router.stack.map((page) => page.name), [
        'HomeRoute',
        'DetailsRoute',
      ]);
    },
    variant: TargetPlatformVariant.only(.iOS),
  );

  // Apps that don't opt in keep today's behavior: a custom transition has no
  // back swipe.
  testWidgets(
    'A custom-transition page without the option ignores a back swipe',
    (tester) async {
      final router = _router(enableCupertinoBackGesture: false);
      await _pumpAtDetails(tester, router);

      await swipeBack(tester);

      expect(router.stack.map((page) => page.name), [
        'HomeRoute',
        'DetailsRoute',
      ]);
    },
    variant: TargetPlatformVariant.only(.iOS),
  );

  // The iOS back swipe belongs to iOS and macOS, as in Flutter's default
  // page transitions; Android has its own back gesture.
  testWidgets('enableCupertinoBackGesture adds no back swipe on Android', (
    tester,
  ) async {
    final router = _router(enableCupertinoBackGesture: true);
    await _pumpAtDetails(tester, router);

    await swipeBack(tester);

    expect(router.stack.map((page) => page.name), [
      'HomeRoute',
      'DetailsRoute',
    ]);
  }, variant: TargetPlatformVariant.only(.android));

  // As with a CupertinoPageRoute, a full screen dialog closes by its own
  // button, not by a back swipe.
  testWidgets(
    'A full screen dialog with enableCupertinoBackGesture ignores a back swipe',
    (tester) async {
      final router = _router(
        enableCupertinoBackGesture: true,
        fullscreenDialog: true,
      );
      await _pumpAtDetails(tester, router);

      await swipeBack(tester);

      expect(router.stack.map((page) => page.name), [
        'HomeRoute',
        'DetailsRoute',
      ]);
    },
    variant: TargetPlatformVariant.only(.iOS),
  );
}
