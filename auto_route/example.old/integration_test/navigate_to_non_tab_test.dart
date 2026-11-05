import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/pages.dart';

// navigate from a tab to a child route of the tabs host that is not one of
// its tabs reports a failure instead of doing nothing.
// https://github.com/Milad-Akarie/auto_route_library/issues/1371
// Headless test: auto_route/test/nested_tabs_router/navigate_to_non_tab_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: SectionRoute with children PagerPage1Route, PagerPage2Route and
  // OtherExternalPageRoute; its AutoTabsRouter shows the first two. From the
  // first tab, navigate to OtherExternalPageRoute with onFailure.
  // Should: onFailure gets a RouteNotFoundFailure and the tab stays on screen.
  testWidgets('navigate to a child route that is not a tab reports a failure', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'SectionRoute',
          path: '/',
          builder: (_, _) => AutoTabsRouter(
            routes: const [
              NamedRoute('PagerPage1Route'),
              NamedRoute('PagerPage2Route'),
            ],
            builder: (_, child) => child,
          ),
          children: [
            NamedRouteDef(
              name: 'PagerPage1Route',
              path: 'page1',
              builder: (_, _) => const TextPage('Pager 1'),
            ),
            NamedRouteDef(
              name: 'PagerPage2Route',
              path: 'page2',
              builder: (_, _) => const TextPage('Pager 2'),
            ),
            NamedRouteDef(
              name: 'OtherExternalPageRoute',
              path: 'other',
              builder: (_, _) => const TextPage('Other'),
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    final tabs = tester.element(find.text('Pager 1')).router;
    final failures = <NavigationFailure>[];

    unawaited(
      tabs.navigate(
        const NamedRoute('OtherExternalPageRoute'),
        onFailure: failures.add,
      ),
    );
    await tester.pumpAndSettle();

    expect(failures.singleOrNull, isA<RouteNotFoundFailure>());
    expect(find.text('Pager 1'), findsOneWidget);
    expect(find.text('Other'), findsNothing);
  });
}
