import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../back_test_utils.dart';

// Found while fixing #1759 (homeIndex ignored after a rebuild): the same shape
// of bug was suspected for backThroughHistory.
// Setup: an AutoTabsRouter, over a first page, rebuilt by its parent with
// another backThroughHistory.
// Steps: show tab 0, rebuild the tabs with the other value, show tab 2, then
// 1, and press Android's back key.
// A third test: turning it off while a tab waits in the history tells Android
// the app no longer takes back.
// Expected: back follows the value of the latest build, as the other
// properties of the widget do: with true it shows 2, then 0; with false it
// leaves the tabs.
void main() {
  late ValueNotifier<bool> shouldGoBackThroughHistory;
  late FrameworkHandlesBackRecorder frameworkHandlesBack;

  Future<(RootStackRouter, TabsRouter)> pumpApp(
    WidgetTester tester, {
    required bool initial,
    bool isOverFirstPage = true,
  }) async {
    shouldGoBackThroughHistory = ValueNotifier(initial);
    addTearDown(shouldGoBackThroughHistory.dispose);
    final tabsPage = PageInfo(
      'TabsRoute',
      builder: (_) => ValueListenableBuilder<bool>(
        valueListenable: shouldGoBackThroughHistory,
        builder: (_, value, _) => AutoTabsRouter(
          backThroughHistory: value,
          routes: [for (final name in _kTabNames) _Route(name)],
        ),
      ),
    );
    final router = RootStackRouter.build(
      routes: [
        if (isOverFirstPage) AutoRoute(page: _page('FirstRoute'), path: '/'),
        AutoRoute(
          page: tabsPage,
          path: isOverFirstPage ? '/tabs' : '/',
          children: [
            for (final name in _kTabNames)
              AutoRoute(page: _page(name), path: name),
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
    return (router, router.innerRouterOf<TabsRouter>(tabsPage.name)!);
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

  testWidgets('backThroughHistory changed from false to true takes effect', (
    tester,
  ) async {
    final (_, tabs) = await pumpApp(tester, initial: false);
    shouldGoBackThroughHistory.value = true;
    await tester.pumpAndSettle();
    await visit(tester, tabs, [2, 1]);

    await systemBack(tester);

    expect(tabs.backThroughHistory, isTrue);
    expect(tabs.activeIndex, 2);
    expect(find.text('FeedRoute'), findsNothing);
    expect(find.text('RankingRoute'), findsOneWidget);
  });

  testWidgets('backThroughHistory changed from true to false takes effect', (
    tester,
  ) async {
    final (_, tabs) = await pumpApp(tester, initial: true);
    shouldGoBackThroughHistory.value = false;
    await tester.pumpAndSettle();
    await visit(tester, tabs, [2, 1]);

    await systemBack(tester);

    expect(tabs.backThroughHistory, isFalse);
    expect(find.text('FirstRoute'), findsOneWidget);
    expect(find.text('FeedRoute'), findsNothing);
  });

  testWidgets(
    'backThroughHistory turned off tells Android the app no longer takes back',
    (tester) async {
      // The tabs are the only page: the root navigator has nothing to pop.
      final (_, tabs) = await pumpApp(
        tester,
        initial: true,
        isOverFirstPage: false,
      );
      await visit(tester, tabs, [2, 1]);
      expect(frameworkHandlesBack.isHandlingBack, isTrue);

      shouldGoBackThroughHistory.value = false;
      await tester.pumpAndSettle();

      expect(frameworkHandlesBack.isHandlingBack, isFalse);
    },
    skip: kIsWeb,
  );
}

const List<String> _kTabNames = [
  'NewsRoute',
  'FeedRoute',
  'RankingRoute',
  'ProfileRoute',
];

PageInfo _page(String name) => .new(name, builder: (_) => Text(name));

class _Route extends PageRouteInfo<void> {
  const new(super.name);
}
