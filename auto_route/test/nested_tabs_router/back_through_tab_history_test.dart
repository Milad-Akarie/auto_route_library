import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../back_test_utils.dart';

// Feature request https://github.com/Milad-Akarie/auto_route_library/issues/1789
// (also #830): back in a tabs screen goes to the tab the user came from.
// Setup, as in the request: an AutoTabsRouter whose tabs are switched with
// setActiveIndex, as a bottom bar's onTap does.
// Steps: show tab 0, then 2, then 1, and press Android's back key.
// Before: back jumps to homeIndex, or leaves the tabs when there is none.
// Now, with backThroughHistory: back shows 2, then 0, then leaves the tabs.
// While a tab is left to go back to, Flutter tells Android it handles back,
// so Android 13 and later doesn't close the app instead.
void main() {
  late FrameworkHandlesBackRecorder frameworkHandlesBack;

  Future<TabsRouter> pumpApp(
    WidgetTester tester, {
    bool shouldGoBackThroughHistory = true,
    int homeIndex = -1,
    bool isOverFirstPage = false,
  }) async {
    _shouldGoBackThroughHistory = shouldGoBackThroughHistory;
    _homeIndex = homeIndex;
    final router = RootStackRouter.build(
      routes: [
        if (isOverFirstPage) AutoRoute(page: _page('FirstRoute'), path: '/'),
        AutoRoute(
          page: _tabsPage,
          path: isOverFirstPage ? '/tabs' : '/',
          children: [
            for (final name in _kTabNames)
              AutoRoute(
                page: _page(name),
                path: name,
                guards: [
                  if (name == _kGuardedTab)
                    AutoRouteGuard.simple(
                      (resolver, _) =>
                          _shouldReject ? resolver.reject() : resolver.next(),
                    ),
                ],
              ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    frameworkHandlesBack = FrameworkHandlesBackRecorder()..listen(tester);
    await tester.pumpWidget(
      MaterialApp.router(theme: androidTheme, routerConfig: router.config()),
    );
    await tester.pumpAndSettle();
    if (isOverFirstPage) {
      unawaited(router.push(const _Route('TabsRoute')));
      await tester.pumpAndSettle();
    }
    return router.innerRouterOf<TabsRouter>(_tabsPage.name)!;
  }

  Future<void> visit(
    WidgetTester tester,
    TabsRouter tabs,
    List<int> indexes,
  ) async {
    for (final index in indexes) {
      tabs.setActiveIndex(index);
      await tester.pumpAndSettle();
    }
  }

  void expectTab(TabsRouter tabs, int index) {
    expect(tabs.activeIndex, index);
    expect(find.text(_kTabNames.elementAtOrNull(index)!), findsOneWidget);
  }

  setUp(() => _shouldReject = false);

  for (final MapEntry(key: name, value: back) in {
    'system back': systemBack,
    'the predictive back gesture': predictiveBack,
  }.entries) {
    testWidgets(
      '$name after tabs 0, 2, 1 shows 2, then 0, then Android closes the app',
      (tester) async {
        final tabs = await pumpApp(tester);
        expect(frameworkHandlesBack.isHandlingBack, isFalse);
        await visit(tester, tabs, [2, 1]);
        expect(frameworkHandlesBack.isHandlingBack, isTrue);

        await back(tester);
        expectTab(tabs, 2);
        expect(
          frameworkHandlesBack.isHandlingBack,
          isTrue,
          reason: 'after back(tester)',
        );

        await back(tester);
        expectTab(tabs, 0);
        expect(
          frameworkHandlesBack.isHandlingBack,
          isFalse,
          reason: 'after back(tester)',
        );
      },
      skip: kIsWeb,
    );
  }

  testWidgets('back after tabs 0, 2, 1 shows 2, then 0, then leaves the tabs', (
    tester,
  ) async {
    final tabs = await pumpApp(tester, isOverFirstPage: true);
    await visit(tester, tabs, [2, 1]);

    await systemBack(tester);
    expectTab(tabs, 2);
    await systemBack(tester);
    expectTab(tabs, 0);
    await systemBack(tester);
    expect(find.text('FirstRoute'), findsOneWidget);
    expect(find.text(_kFirstTab), findsNothing);
  });

  testWidgets('popping the tabs router walks the same history', (tester) async {
    final tabs = await pumpApp(tester, isOverFirstPage: true);
    await visit(tester, tabs, [2, 1]);

    expect(await tabs.maybePop(), isTrue);
    await tester.pumpAndSettle();
    expectTab(tabs, 2);
    tabs.pop();
    await tester.pumpAndSettle();
    expectTab(tabs, 0);
    tabs.pop();
    await tester.pumpAndSettle();
    expect(find.text('FirstRoute'), findsOneWidget);
  });

  testWidgets(
    'a tab visited again is gone back to once, from where it was visited last',
    (tester) async {
      final tabs = await pumpApp(tester, isOverFirstPage: true);
      await visit(tester, tabs, [1, 0, 2]);

      await systemBack(tester);
      expectTab(tabs, 0);
      await systemBack(tester);
      expectTab(tabs, 1);
      await systemBack(tester);
      expect(find.text('FirstRoute'), findsOneWidget);
    },
  );

  testWidgets('back skips a tab whose guards keep it out', (tester) async {
    final tabs = await pumpApp(tester, isOverFirstPage: true);
    await visit(tester, tabs, [2, 1]);
    _shouldReject = true;

    await systemBack(tester);
    expectTab(tabs, 0);
  });

  testWidgets(
    'with a homeIndex, back shows the home tab once the history is gone '
    'through',
    (tester) async {
      final tabs = await pumpApp(tester, homeIndex: 0, isOverFirstPage: true);
      await visit(tester, tabs, [1, 0, 3]);

      await systemBack(tester);
      expectTab(tabs, 0);
      await systemBack(tester);
      expectTab(tabs, 1);
      await systemBack(tester);
      expectTab(tabs, 0);
      await systemBack(tester);
      expect(find.text('FirstRoute'), findsOneWidget);
    },
  );

  testWidgets('without backThroughHistory, back leaves the tabs from any tab', (
    tester,
  ) async {
    final tabs = await pumpApp(
      tester,
      shouldGoBackThroughHistory: false,
      isOverFirstPage: true,
    );
    await visit(tester, tabs, [2, 1]);

    await systemBack(tester);
    expect(find.text('FirstRoute'), findsOneWidget);
  });
}

const _kFirstTab = 'NewsRoute';
const _kGuardedTab = 'RankingRoute';
const List<String> _kTabNames = [
  _kFirstTab,
  'FeedRoute',
  _kGuardedTab,
  'ProfileRoute',
];
var _shouldGoBackThroughHistory = true;
var _homeIndex = -1;
var _shouldReject = false;

final _tabsPage = PageInfo(
  'TabsRoute',
  builder: (_) => AutoTabsRouter(
    backThroughHistory: _shouldGoBackThroughHistory,
    homeIndex: _homeIndex,
    routes: [for (final name in _kTabNames) _Route(name)],
  ),
);

PageInfo _page(String name) => .new(name, builder: (_) => Text(name));

class _Route extends PageRouteInfo<void> {
  const new(super.name);
}
