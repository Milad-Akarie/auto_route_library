import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// Back on a tab away from the home tab shows the home tab.
// https://github.com/Milad-Akarie/auto_route_library/issues/2059
// Headless test: auto_route/test/nested_tabs_router/home_index_back_test.dart
//
// Setup, as in the report: the app's first page is an AutoTabsScaffold with
// several tabs and a homeIndex.
// Steps: show another tab, then press system back. On Android that goes
// through the activity, which Android calls only while Flutter says it
// handles back (see systemBack). A comment sets homeIndex: 1, so the app
// starts away from its home tab.
// Reported: on Android the app closed.
// Should: back shows the home tab; only there would Android close the app.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<TabsRouter> pumpApp(
    WidgetTester tester, {
    required int homeIndex,
  }) async {
    _homeIndex = homeIndex;
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: _tabsPage,
          path: '/',
          children: [
            for (final name in _kTabNames)
              AutoRoute(page: _page(name), path: name),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    return router.innerRouterOf<TabsRouter>(_tabsPage.name)!;
  }

  testWidgets('system back on another tab shows the home tab', (tester) async {
    final tabs = await pumpApp(tester, homeIndex: 0);
    tabs.setActiveIndex(2);
    await tester.pumpAndSettle();

    await systemBack(tester);

    expect(tabs.activeIndex, 0);
    expect(find.text(_kTabNames[0]), findsOneWidget);
    expect(await androidSendsBackToFlutter(), anyOf(isNull, isFalse));
  });

  testWidgets(
    'system back on the first tab shows the home tab when homeIndex is another',
    (tester) async {
      final tabs = await pumpApp(tester, homeIndex: 1);
      expect(tabs.activeIndex, 0);

      await systemBack(tester);

      expect(tabs.activeIndex, 1);
      expect(find.text(_kTabNames[1]), findsOneWidget);
    },
  );
}

const _kTabNames = ['NewsRoute', 'FeedRoute', 'RankingRoute', 'ProfileRoute'];
var _homeIndex = 0;

final _tabsPage = PageInfo(
  'HomeRoute',
  builder: (_) => AutoTabsScaffold(
    homeIndex: _homeIndex,
    routes: [for (final name in _kTabNames) _Route(name)],
  ),
);

PageInfo _page(String name) => .new(name, builder: (_) => Text(name));

class _Route extends PageRouteInfo<void> {
  const new(super.name);
}
