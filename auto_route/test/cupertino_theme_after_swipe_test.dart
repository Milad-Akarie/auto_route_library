import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'back_test_utils.dart';

// flutter/flutter#83183: on Android, with a theme whose page transitions are
// CupertinoPageTransitionsBuilder, an edge swipe back made the next page
// transitions fall back to Flutter's default for Android.
// Steps: Android theme with the Cupertino builder for every platform; push
// P2, swipe back from the left edge, then push P2 again.
// Should: the swipe pops P2, and the second push slides in with the
// Cupertino transition again.
void main() {
  testWidgets('after a back swipe on Android, a push keeps the Cupertino transition of the theme', (tester) async {
    final theme = ThemeData(
      platform: .android,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {for (final platform in TargetPlatform.values) platform: const CupertinoPageTransitionsBuilder()},
      ),
    );
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('P1', builder: (_) => const Scaffold(body: Text('P1'))),
        ),
        AutoRoute(
          path: '/p2',
          page: PageInfo('P2', builder: (_) => const Scaffold(body: Text('P2'))),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(theme: theme, routerConfig: router.config()));
    await tester.pumpAndSettle();
    final cupertinoTransition = find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == 'CupertinoPageTransition',
    );

    unawaited(router.pushPath('/p2'));
    await tester.pumpAndSettle();
    await swipeBack(tester);
    expect(router.stack.map((page) => page.name), ['P1']);

    unawaited(router.pushPath('/p2'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(cupertinoTransition, findsWidgets);
    await tester.pumpAndSettle();
    expect(find.text('P2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
