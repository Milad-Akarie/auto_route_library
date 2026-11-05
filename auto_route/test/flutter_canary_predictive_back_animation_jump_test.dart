import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'no_op.dart';

// Canary for Flutter bug https://github.com/flutter/flutter/issues/184653
// (TransitionRoute.animation jumps to its end when a predictive back gesture
// commits the pop).
// Setup, as in the Flutter report, without auto_route: Android, a page route
// whose transition reads the route's animation, predictive back on.
// Steps: push a page, start the back gesture, drag to progress 0.5, commit.
// Should: the animation value goes on from the dragged value, falling
// towards 0 (the page leaves).
// Today, on Flutter 3.47.9 with material_ui 1.10.0: dragged to 0.5, the value
// is 1.0 in the first frame after the commit, then falls. If this test fails after a Flutter upgrade, the animation of a
// custom route transition, including auto_route's RouteType.custom ones,
// reacts differently to the commit: check that they still look right.
void main() {
  testWidgets('the route animation value on a predictive back commit, until Flutter fixes '
      'flutter/flutter#184653', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: .android),
        home: Builder(
          builder: (c) {
            context = c;
            return const Scaffold(body: Text('home'));
          },
        ),
      ),
    );
    final route = MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('second')));
    Navigator.of(context).push(route);
    await tester.pumpAndSettle();
    expect(route.animation!.value, 1.0);

    Future<void> send(String method, [Map<String, Object?>? arguments]) async {
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.backGesture.name,
        const StandardMethodCodec().encodeMethodCall(MethodCall(method, arguments)),
        ignoreArgument,
      );
      await tester.pump();
    }

    Map<String, Object?> event(double x, double progress) => {
      'touchOffset': [x, 300.0],
      'progress': progress,
      'swipeEdge': 0,
    };
    await send('startBackGesture', event(5, 0));
    await send('updateBackGestureProgress', event(150, 0.5));
    final dragged = route.animation!.value;
    await send('commitBackGesture');
    expect(dragged, closeTo(0.5, 0.1));
    expect(route.animation!.value, 1.0);
    await tester.pumpAndSettle();
    expect(route.animation!.value, 0.0);
  });
}
