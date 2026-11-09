import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/tab_history_router.dart';

// The backThroughHistory flag of AutoTabsRouter follows the latest build: a
// parent that rebuilds the tabs with another value changes where back goes.
// Found while fixing #1759 (homeIndex ignored after a rebuild), and no issue
// reports it. The headless test is
// auto_route/test/nested_tabs_router/back_through_history_rebuild_test.dart.
//
// Steps: show the tabs over a first page and rebuild them with the other
// value, then show tab 2 and tab 1, and press system back.
// Should: with true, back shows 2; with false, back leaves the tabs for the
// page under them.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('tab history back after a rebuild', () {
    late ValueNotifier<bool> shouldGoBackThroughHistory;

    Future<TabsRouter> pumpApp(
      WidgetTester tester, {
      required bool initial,
    }) async {
      shouldGoBackThroughHistory = ValueNotifier(initial);
      addTearDown(shouldGoBackThroughHistory.dispose);
      final tabsPage = PageInfo(
        kTabHistoryTabsName,
        builder: (_) => ValueListenableBuilder<bool>(
          valueListenable: shouldGoBackThroughHistory,
          builder: (_, value, _) => AutoTabsRouter(
            backThroughHistory: value,
            routes: [for (final name in kTabHistoryTabNames) _Route(name)],
          ),
        ),
      );
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(page: _page(kTabHistoryFirstPageName), path: '/'),
          AutoRoute(
            page: tabsPage,
            path: '/tabs',
            children: [
              for (final name in kTabHistoryTabNames)
                AutoRoute(page: _page(name), path: name),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await pumpRouterApp(tester, router);
      unawaited(router.push(kTabHistoryTabsRoute));
      await tester.pumpAndSettle();
      return router.innerRouterOf<TabsRouter>(kTabHistoryTabsName)!;
    }

    Future<void> rebuildAndVisit(
      WidgetTester tester,
      TabsRouter tabs, {
      required bool value,
    }) async {
      shouldGoBackThroughHistory.value = value;
      await tester.pumpAndSettle();
      for (final index in [2, 1]) {
        tabs.setActiveIndex(index);
        await tester.pumpAndSettle();
      }
    }

    testWidgets('turned on by a rebuild, system back shows tab 2', (
      tester,
    ) async {
      final tabs = await pumpApp(tester, initial: false);
      await rebuildAndVisit(tester, tabs, value: true);

      await systemBack(tester);

      expect(tabs.activeIndex, 2);
      expect(find.text('RankingRoute'), findsOneWidget);
    });

    testWidgets('turned off by a rebuild, system back leaves the tabs', (
      tester,
    ) async {
      final tabs = await pumpApp(tester, initial: true);
      await rebuildAndVisit(tester, tabs, value: false);

      await systemBack(tester);

      expect(find.text(kTabHistoryFirstPageName), findsOneWidget);
      expect(find.text('FeedRoute'), findsNothing);
    });
  });
}

PageInfo _page(String name) => .new(
  name,
  builder: (_) => Scaffold(body: Center(child: Text(name))),
);

class _Route extends PageRouteInfo<void> {
  const new(super.name);
}
