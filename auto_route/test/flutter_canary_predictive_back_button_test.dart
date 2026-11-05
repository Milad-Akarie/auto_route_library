import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'back_test_utils.dart';

// Canary for Flutter bugs https://github.com/flutter/flutter/issues/183635
// (no predictive back animation from the back button in 3-button
// navigation) and https://github.com/flutter/flutter/issues/186168
// (PredictiveBackEvent.fromMap throws on that button's events), behind
// https://github.com/Milad-Akarie/auto_route_library/issues/2303.
// Setup, as in the report: Android 16, 3-button navigation, routes with
// RouteType.material(enablePredictiveBackGesture: true).
// Steps: push a page, then long-press the back button. From API 36 Android
// sends the predictive back messages with swipeEdge 2 (BackEvent.EDGE_NONE)
// and a zero touch offset, the same as Flutter PR #183642 logged on API 36
// and this fork saw on the Pixel_9_Pro_Fold emulator (API 37).
// Today, on Flutter 3.47.9 with material_ui 1.10.0: Flutter can't read
// swipeEdge 2 and answers startBackGesture with a RangeError, so no
// predictive animation starts, and letting go pops the page like a plain
// back. Flutter's own predictive back builder also skips button events.
// If this test fails after a Flutter upgrade, Flutter changed how it
// handles back button events: check whether the long press now animates
// with auto_route's routes too, and revisit #2303.
void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      defaultRouteType: const RouteType.material(
        enablePredictiveBackGesture: true,
      ),
      routes: [
        NamedRouteDef(
          name: 'FirstRoute',
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('FirstRoute')),
        ),
        NamedRouteDef(
          name: 'SecondRoute',
          path: '/second',
          builder: (_, _) => const Scaffold(body: Text('SecondRoute')),
        ),
      ],
    );
    addTearDown(router.dispose);
  });

  Future<void> pushSecond(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp.router(theme: androidTheme, routerConfig: router.config()),
    );
    await tester.pumpAndSettle();
    unawaited(router.pushPath('/second'));
    await tester.pumpAndSettle();
    expect(router.topRoute.name, 'SecondRoute');
  }

  // Sends one back gesture message the way the engine does and returns
  // Flutter's reply.
  Future<Object?> send(
    WidgetTester tester,
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    const codec = StandardMethodCodec();
    Object? reply;
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.backGesture.name,
      codec.encodeMethodCall(MethodCall(method, arguments)),
      (data) {
        try {
          reply = codec.decodeEnvelope(data!);
        } on PlatformException catch (error) {
          reply = error;
        }
      },
    );
    await tester.pump();
    return reply;
  }

  bool animatingBack(WidgetTester tester) =>
      ModalRoute.of(tester.element(find.text('SecondRoute')))!
          .popGestureInProgress;

  testWidgets('an edge swipe still starts the predictive back animation', (
    tester,
  ) async {
    await pushSecond(tester);
    Map<String, Object?> swipe(double x, double progress) => {
      'touchOffset': [x, 300.0],
      'progress': progress,
      'swipeEdge': 0,
    };
    expect(await send(tester, 'startBackGesture', swipe(5, 0)), isTrue);
    await send(tester, 'updateBackGestureProgress', swipe(150, 0.5));
    expect(animatingBack(tester), isTrue);

    await send(tester, 'commitBackGesture');
    await tester.pumpAndSettle();
    expect(router.topRoute.name, 'FirstRoute');
  });

  testWidgets(
    'a long press on the 3-button back button starts no animation and pops on '
    'release, '
    'until Flutter fixes flutter/flutter#183635 and #186168',
    (tester) async {
      await pushSecond(tester);
      Map<String, Object?> button(double progress) => {
        'touchOffset': [0.0, 0.0],
        'progress': progress,
        'swipeEdge': 2,
      };
      final started = await send(tester, 'startBackGesture', button(0));
      expect(
        started,
        isA<PlatformException>().having(
          (error) => error.message,
          'message',
          contains('RangeError'),
        ),
      );
      await send(tester, 'updateBackGestureProgress', button(0.5));
      expect(animatingBack(tester), isFalse);

      await send(tester, 'commitBackGesture');
      await tester.pumpAndSettle();
      expect(router.topRoute.name, 'FirstRoute');
    },
  );

  testWidgets(
    "material_ui's predictive back builder skips a back button event, until "
    'Flutter fixes '
    'flutter/flutter#183635',
    (tester) async {
      await pushSecond(tester);
      // A back button event Flutter can read: zero touch offset and progress.
      final started = await send(tester, 'startBackGesture', {
        'touchOffset': [0.0, 0.0],
        'progress': 0.0,
        'swipeEdge': 0,
      });
      expect(started, isFalse);
      expect(animatingBack(tester), isFalse);
    },
  );
}
