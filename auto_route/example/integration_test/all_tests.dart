import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'app_smoke_test.dart' as app_smoke;
import 'empty_nested_router_test.dart' as empty_nested_router;
import 'host_back_button_test.dart' as host_back_button;
import 'leading_button_pop_test.dart' as leading_button_pop;
import 'login_state_test.dart' as login_state;
import 'navigate_awaits_test.dart' as navigate_awaits;
import 'navigate_nested_update_test.dart' as navigate_nested_update;
import 'nested_back_test.dart' as nested_back;
import 'overlapping_reevaluation_test.dart' as overlapping_reevaluation;
import 'pop_and_back_test.dart' as pop_and_back;
import 'push_and_reevaluate_test.dart' as push_and_reevaluate;
import 'push_futures_test.dart' as push_futures;
import 'query_params_on_pop_test.dart' as query_params_on_pop;
import 'reevaluation_nested_tabs_test.dart' as reevaluation_nested_tabs;
import 'reevaluation_redirect_test.dart' as reevaluation_redirect;
import 'replaced_push_future_test.dart' as replaced_push_future;
import 'tab_rebuild_test.dart' as tab_rebuild;
import 'tab_routes_change_test.dart' as tab_routes_change;
import 'url_on_pop_test.dart' as url_on_pop;

// Runs every integration test file in one app launch. Run this file, not the
// folder: desktop runners fail to relaunch the app for a second file, and
// `flutter drive` on web takes a single target. Add each new test file here.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('app smoke', app_smoke.main);
  group('empty nested router', empty_nested_router.main);
  group('host back button', host_back_button.main);
  group('leading button pop', leading_button_pop.main);
  group('login state', login_state.main);
  group('navigate awaits', navigate_awaits.main);
  group('navigate nested update', navigate_nested_update.main);
  group('nested back', nested_back.main);
  group('overlapping reevaluation', overlapping_reevaluation.main);
  group('pop and back', pop_and_back.main);
  group('push and reevaluate', push_and_reevaluate.main);
  group('push futures', push_futures.main);
  group('query params on pop', query_params_on_pop.main);
  group('reevaluation nested tabs', reevaluation_nested_tabs.main);
  group('reevaluation redirect', reevaluation_redirect.main);
  group('replaced push future', replaced_push_future.main);
  group('tab rebuild', tab_rebuild.main);
  group('tab routes change', tab_routes_change.main);
  group('url on pop', url_on_pop.main);
}
