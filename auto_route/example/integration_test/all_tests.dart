import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'app_smoke_test.dart' as app_smoke;
import 'push_futures_test.dart' as push_futures;

// Runs every integration test file in one app launch. Run this file, not the
// folder: desktop runners fail to relaunch the app for a second file, and
// `flutter drive` on web takes a single target. Add each new test file here.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('app smoke', app_smoke.main);
  group('push futures', push_futures.main);
}
