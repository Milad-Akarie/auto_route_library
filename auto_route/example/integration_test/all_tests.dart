import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'app_smoke_test.dart' as app_smoke;
import 'empty_nested_router_test.dart' as empty_nested_router;
import 'login_state_test.dart' as login_state;
import 'navigate_awaits_test.dart' as navigate_awaits;
import 'overlapping_reevaluation_test.dart' as overlapping_reevaluation;
import 'push_futures_test.dart' as push_futures;
import 'reevaluation_nested_tabs_test.dart' as reevaluation_nested_tabs;
import 'reevaluation_redirect_test.dart' as reevaluation_redirect;
import 'replaced_push_future_test.dart' as replaced_push_future;
import 'url_on_pop_test.dart' as url_on_pop;

// Runs every integration test file in one app launch. Run this file, not the
// folder: desktop runners fail to relaunch the app for a second file, and
// `flutter drive` on web takes a single target. Add each new test file here.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('app smoke', app_smoke.main);
  group('empty nested router', empty_nested_router.main);
  group('login state', login_state.main);
  group('navigate awaits', navigate_awaits.main);
  group('overlapping reevaluation', overlapping_reevaluation.main);
  group('push futures', push_futures.main);
  group('reevaluation nested tabs', reevaluation_nested_tabs.main);
  group('reevaluation redirect', reevaluation_redirect.main);
  group('replaced push future', replaced_push_future.main);
  group('url on pop', url_on_pop.main);
}
