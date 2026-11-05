import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../back_test_utils.dart';
import '../router_test_utils.dart';

// flutter/flutter#138737: a PopScope's onPopInvokedWithResult should hear
// every back, with didPop true when the page is popped and false when
// PopScope(canPop: false) keeps it. pop_scope_once_test.dart checks this for
// flat and nested stacks; this is the tabs variant.
// Steps: from Home, push a page that holds an AutoTabsRouter
// [TabA, TabB], wrapped in a PopScope; go back by system back, the predictive back
// gesture, the app bar back button or the iOS swipe.
void main() {
  late RootStackRouter router;
  setUp(() {
    _heard.clear();
    _homeIndex = -1;
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('Home'), initial: true),
        AutoRoute(
          page: _tabsScreen,
          children: [
            AutoRoute(page: _page('TabA')),
            AutoRoute(page: _page('TabB')),
          ],
        ),
      ],
    );
  });

  Future<void> openTabsScreen(
    WidgetTester tester, {
    required bool canPop,
    ThemeData? theme,
  }) async {
    _canPop = canPop;
    tester.binding.handleAppLifecycleStateChanged(.resumed);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: theme, routerConfig: router.config()),
    );
    await tester.pumpAndSettle();
    unawaited(router.push(PageRouteInfo(_tabsScreen.name)));
    await tester.pumpAndSettle();
  }

  final backs = <String, (Future<void> Function(WidgetTester), ThemeData?)>{
    'system back': (systemBack, null),
    'the predictive back gesture': (predictiveBack, androidTheme),
    'the app bar back button': (tapLeadingBackButton, null),
    'the iOS back swipe': (swipeBack, iosTheme),
  };

  for (final MapEntry(key: name, value: (back, theme)) in backs.entries) {
    testWidgets(
      '$name pops the tabs screen, and its PopScope hears didPop true',
      (tester) async {
        await openTabsScreen(tester, canPop: true, theme: theme);

        await back(tester);

        expectTopPage(router, 'Home');
        expect(_heard, [true]);
      },
    );

    // The iOS swipe doesn't start while PopScope blocks the page.
    if (back == swipeBack) continue;

    testWidgets(
      '$name with PopScope(canPop: false) keeps the tabs screen, and PopScope hears each back',
      (tester) async {
        await openTabsScreen(tester, canPop: false, theme: theme);

        await back(tester);
        expect(_heard, [false]);
        await back(tester);
        expect(_heard, [false, false]);

        expect(router.topRoute.name, 'TabA');
        expect(router.stack.lastOrNull?.name, _tabsScreen.name);
      },
    );
  }

  testWidgets(
    'system back on the second tab asks PopScope, and keeps the second tab',
    (tester) async {
      await openTabsScreen(tester, canPop: false);
      router.innerRouterOf<TabsRouter>(_tabsScreen.name)!.setActiveIndex(1);
      await tester.pumpAndSettle();

      await systemBack(tester);
      expect(router.topRoute.name, 'TabB');
      expect(_heard, [false]);
    },
  );

  // With a homeIndex, back on another tab shows the home tab first, as
  // home_index_back_test.dart pins, so PopScope hears the next back.
  testWidgets(
    'system back on the second tab with homeIndex 0 shows the first tab, then asks PopScope',
    (tester) async {
      _homeIndex = 0;
      await openTabsScreen(tester, canPop: false);
      router.innerRouterOf<TabsRouter>(_tabsScreen.name)!.setActiveIndex(1);
      await tester.pumpAndSettle();

      await systemBack(tester);
      expect(router.topRoute.name, 'TabA');
      expect(_heard, isEmpty);

      await systemBack(tester);
      expect(router.topRoute.name, 'TabA', reason: 'after systemBack(tester)');
      expect(_heard, [false]);
    },
  );
}

final _heard = <bool>[];
var _canPop = true;
var _homeIndex = -1;

final _tabsScreen = PageInfo(
  'TabsScreen',
  builder: (_) => PopScope(
    canPop: _canPop,
    onPopInvokedWithResult: (didPop, _) => _heard.add(didPop),
    child: Scaffold(
      appBar: AppBar(leading: const AutoLeadingButton()),
      body: AutoTabsRouter(
        homeIndex: _homeIndex,
        routes: const [PageRouteInfo('TabA'), PageRouteInfo('TabB')],
      ),
    ),
  ),
);

PageInfo _page(String name) => .new(name, builder: (_) => Text(name));
