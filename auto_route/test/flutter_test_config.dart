import 'dart:async';

import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

/// Runs every headless test with Flutter's leak tracking, so a disposable
/// object that is created and never disposed fails the test file that made
/// it. Set `LeakTesting.settings =
/// LeakTesting.settings.withCreationStackTrace()` to see where a leaked object
/// was created.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  LeakTesting.enable();
  await testMain();
}
