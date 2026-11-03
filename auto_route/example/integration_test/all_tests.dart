import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'app_smoke_test.dart' as app_smoke;
import 'overlapping_reevaluation_test.dart' as overlapping_reevaluation;
import 'push_futures_test.dart' as push_futures;
import 'reevaluation_nested_tabs_test.dart' as reevaluation_nested_tabs;
import 'reevaluation_redirect_test.dart' as reevaluation_redirect;
import 'replaced_push_future_test.dart' as replaced_push_future;

// Runs every integration test file in one app launch. Run this file, not the
// folder: desktop runners fail to relaunch the app for a second file, and
// `flutter drive` on web takes a single target. Add each new test file here.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('app smoke', app_smoke.main);
  group('overlapping reevaluation', overlapping_reevaluation.main);
  group('push futures', push_futures.main);
  group('reevaluation nested tabs', reevaluation_nested_tabs.main);
  group('reevaluation redirect', reevaluation_redirect.main);
  group('replaced push future', replaced_push_future.main);
}
