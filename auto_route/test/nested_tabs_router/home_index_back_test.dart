import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../back_test_utils.dart';

// Reproduction for https://github.com/Milad-Akarie/auto_route_library/issues/2059
// Setup, as in the report (Flutter 3.24, auto_route 9.2.2): the app's first
// page is an AutoTabsScaffold with several tabs and a homeIndex, so back on
// another tab shows the home tab.
// Steps: show another tab, then press Android's back key or make the
// predictive back gesture. A comment sets homeIndex: 1, so the app starts
// away from its home tab.
// Happens: on Android 13 and later the app closes. Flutter tells Android it
// doesn't handle back, because the root navigator has one page, so Android
// never sends back to Flutter.
// Should: Flutter tells Android it handles back while the tabs router is
// away from its home tab; back shows the home tab, and only then would
// Android close the app.
// Android only: on web Flutter never tells the platform whether it handles back.
void main() {
  late FrameworkHandlesBackRecorder frameworkHandlesBack;

  Future<TabsRouter> pumpApp(WidgetTester tester, {required int homeIndex}) async {
    _homeIndex = homeIndex;
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: _tabsPage,
          path: '/',
          children: [for (final name in _kTabNames) AutoRoute(page: _page(name), path: name)],
        ),
      ],
    );
    addTearDown(router.dispose);
    frameworkHandlesBack = FrameworkHandlesBackRecorder()..listen(tester);
    await tester.pumpWidget(MaterialApp.router(theme: androidTheme, routerConfig: router.config()));
    await tester.pumpAndSettle();
    return router.innerRouterOf<TabsRouter>(_tabsPage.name)!;
  }

  for (final MapEntry(key: name, value: back) in {
    'system back': systemBack,
    'the predictive back gesture': predictiveBack,
  }.entries) {
    testWidgets('$name on another tab should show the home tab, and keep the app open', (tester) async {
      final tabs = await pumpApp(tester, homeIndex: 0);
      expect(frameworkHandlesBack.last, isFalse);
      tabs.setActiveIndex(2);
      await tester.pumpAndSettle();
      expect(frameworkHandlesBack.last, isTrue);

      await back(tester);

      expect(tabs.activeIndex, 0);
      expect(find.text(_kFirstTab), findsOneWidget);
      expect(frameworkHandlesBack.last, isFalse);
    }, skip: kIsWeb);
  }

  testWidgets('system back on the first tab should show the home tab when homeIndex is another', (tester) async {
    final tabs = await pumpApp(tester, homeIndex: 1);
    expect(tabs.activeIndex, 0);
    expect(frameworkHandlesBack.last, isTrue);

    await systemBack(tester);

    expect(tabs.activeIndex, 1);
    expect(frameworkHandlesBack.last, isFalse);
  }, skip: kIsWeb);
}

const _kFirstTab = 'NewsRoute';
const List<String> _kTabNames = [_kFirstTab, 'FeedRoute', 'RankingRoute', 'ProfileRoute'];
var _homeIndex = 0;

final _tabsPage = PageInfo(
  'HomeRoute',
  builder: (_) => AutoTabsScaffold(homeIndex: _homeIndex, routes: [for (final name in _kTabNames) _Route(name)]),
);

PageInfo _page(String name) => .new(name, builder: (_) => Text(name));

class _Route extends PageRouteInfo<void> {
  const _Route(super.name);
}
