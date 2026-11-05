import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/tab_history_router.dart';

// Back in a tabs screen goes to the tab the user came from, with
// AutoTabsRouter(backThroughHistory: true).
// https://github.com/Milad-Akarie/auto_route_library/issues/1789 (also #830)
// Headless test:
// auto_route/test/nested_tabs_router/back_through_tab_history_test.dart
//
// Steps: show tab 0, then 2, then 1, and press system back. On Android that
// goes through the activity, which Android calls only while Flutter says it
// handles back (see systemBack).
// Should: back shows 2, then 0, then leaves the tabs: the page under them,
// or, when the tabs are the app's first page, Android closes the app.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<TabsRouter> pumpApp(
    WidgetTester tester, {
    bool overFirstPage = false,
  }) async {
    final router = buildTabHistoryRouter(overFirstPage: overFirstPage);
    await pumpRouterApp(tester, router);
    if (overFirstPage) {
      unawaited(router.push(tabHistoryTabsRoute));
      await tester.pumpAndSettle();
    }
    final tabs = router.innerRouterOf<TabsRouter>(tabHistoryTabsName)!;
    for (final index in [2, 1]) {
      tabs.setActiveIndex(index);
      await tester.pumpAndSettle();
    }
    return tabs;
  }

  void expectTab(TabsRouter tabs, int index) {
    expect(tabs.activeIndex, index);
    expect(find.text(tabHistoryTabNames[index]), findsOneWidget);
  }

  testWidgets(
    'system back after tabs 0, 2, 1 shows 2, then 0, then the page under the '
    'tabs',
    (tester) async {
      final tabs = await pumpApp(tester, overFirstPage: true);

      await systemBack(tester);
      expectTab(tabs, 2);
      await systemBack(tester);
      expectTab(tabs, 0);
      await systemBack(tester);
      expect(find.text(tabHistoryFirstPageName), findsOneWidget);
      expect(find.text(tabHistoryTabNames[0]), findsNothing);
    },
  );

  testWidgets(
    'system back after tabs 0, 2, 1 on the first page shows 2, then 0, then '
    'lets the app close',
    (tester) async {
      final tabs = await pumpApp(tester);
      expect(await androidSendsBackToFlutter(), anyOf(isNull, isTrue));

      await systemBack(tester);
      expectTab(tabs, 2);
      expect(await androidSendsBackToFlutter(), anyOf(isNull, isTrue));
      await systemBack(tester);
      expectTab(tabs, 0);
      expect(await androidSendsBackToFlutter(), anyOf(isNull, isFalse));
    },
  );
}
