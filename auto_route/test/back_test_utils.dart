import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// The ways a user goes back, for tests that check a PopScope against each.

/// An Android theme, for the predictive back gesture.
final ThemeData androidTheme = ThemeData(platform: .android);

/// An iOS theme, whose page transitions take the edge swipe.
final ThemeData iosTheme = ThemeData(platform: .iOS);

/// Presses the Android back key, or makes a back gesture without a
/// predictive animation, then waits for the pop to finish.
Future<void> systemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

/// Swipes from the left edge of the screen, the iOS back gesture.
Future<void> swipeBack(WidgetTester tester) async {
  await tester.dragFrom(const Offset(2, 300), const Offset(500, 0));
  await tester.pumpAndSettle();
}

/// Makes Android's predictive back gesture from the left edge, the messages
/// the engine sends while the user drags, then lets go past the threshold.
Future<void> predictiveBack(WidgetTester tester) async {
  Future<void> send(String method, [Map<String, Object?>? arguments]) {
    final message = const StandardMethodCodec().encodeMethodCall(
      MethodCall(method, arguments),
    );
    return tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.backGesture.name,
      message,
      null,
    );
  }

  Map<String, Object?> event(double x, double progress) => {
    'touchOffset': [x, 300.0],
    'progress': progress,
    'swipeEdge': 0,
  };

  await send('startBackGesture', event(5, 0));
  await tester.pump();
  await send('updateBackGestureProgress', event(150, 0.5));
  await tester.pump();
  await send('commitBackGesture');
  await tester.pumpAndSettle();
}

/// Taps the back button an AutoLeadingButton shows, then waits for the pop
/// to finish.
Future<void> tapLeadingBackButton(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton));
  await tester.pumpAndSettle();
}

/// Records whether Flutter tells Android it handles back.
///
/// On Android 13 and later, back goes to Flutter only while the last value
/// is true; while it is false, Android closes the app itself.
class FrameworkHandlesBackRecorder {
  bool? _isHandlingBack;

  /// The last value Flutter sent, or null if it sent none.
  bool? get isHandlingBack => _isHandlingBack;

  /// Starts recording; call it before pumping the app.
  void listen(WidgetTester tester) {
    // Flutter sends the value only while the app is in the foreground.
    tester.binding.handleAppLifecycleStateChanged(.resumed);
    final messenger = tester.binding.defaultBinaryMessenger
      // ignore: function-always-returns-null
      ..setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
          _isHandlingBack = call.arguments as bool;
        }
        return null;
      });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
  }
}
