import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A tab opened by its url keeps the args of its routes list.
// https://github.com/Milad-Akarie/auto_route_library/issues/2107
// Headless test: auto_route/test/pool_b6/tab_bar_required_args_link_test.dart
//
// Setup, as in the report: AutoTabsRouter.tabBar whose second tab's page has
// a required constructor argument, given by the tabs' routes list.
// Steps: start the app on the url of that tab, as a refresh does.
// Reported: MissingRequiredParameterError.
// Should: the tab shows the argument from the routes list.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('tab required args refresh', () {
    testWidgets('a tab opened by its url shows the listed argument', (
      tester,
    ) async {
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            initial: true,
            builder: (_, _) => AutoTabsRouter.tabBar(
              routes: const [
                NamedRoute('TabRoute1'),
                NamedRoute('TabRoute2', args: 'from routes'),
              ],
              builder: (_, child, _) => child,
            ),
            children: [
              NamedRouteDef(
                name: 'TabRoute1',
                path: 'tab1',
                initial: true,
                builder: (_, _) => const Text('Tab 1'),
              ),
              NamedRouteDef(
                name: 'TabRoute2',
                path: 'tab2',
                builder: (_, data) => Text('Tab 2 ${data.argsAs<String>()}'),
              ),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router, initialLink: '/tab2');

      expect(tester.takeException(), isNull);
      expect(find.text('Tab 2 from routes'), findsOneWidget);
    });
  });
}
