import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../back_test_utils.dart';
import '../blocked_pop_scope.dart';
import '../router_test_utils.dart';

// Guard for https://github.com/Milad-Akarie/auto_route_library/issues/2023,
// for the setups its comments report (Flutter 3.24, auto_route 9.2.0):
// the app's first page holds an AutoTabsRouter, and a PopScope(canPop:
// false) sits around that tabs screen, on the active tab's page, or on a
// page pushed into a stack router inside a tab.
// Steps: press Android's back key twice, or make the predictive back
// gesture twice.
// Happened: PopScope heard the first back; on the second, Android closed
// the app, because Flutter had told it the app doesn't handle back.
// Should: the page stays, PopScope hears both, and Flutter keeps telling
// Android it handles back.
// Already works on dev, for each setup and both ways back.
void main() {
  final setups = {
    'around the tabs screen': (
      [
        AutoRoute(page: _tab('TabA'), path: 'a'),
        AutoRoute(page: _tab('TabB'), path: 'b'),
      ],
      scopeAroundTabs: true,
      pushInTab: false,
    ),
    "on the active tab's page": (
      [
        AutoRoute(page: _tab('TabA'), path: 'a'),
        AutoRoute(page: _guarded('TabB'), path: 'b'),
      ],
      scopeAroundTabs: false,
      pushInTab: false,
    ),
    'on a page pushed into a stack inside a tab': (
      [
        AutoRoute(page: _tab('TabA'), path: 'a'),
        AutoRoute(
          page: _stackTab,
          path: 'b',
          children: [
            AutoRoute(page: _tab('StackPage1'), path: ''),
            AutoRoute(page: _guarded('StackPage2'), path: 'two'),
          ],
        ),
      ],
      scopeAroundTabs: false,
      pushInTab: true,
    ),
  };
  final backs = {
    'system back': systemBack,
    'the predictive back gesture': predictiveBack,
  };

  for (final MapEntry(key: where, value: (tabs, :scopeAroundTabs, :pushInTab))
      in setups.entries) {
    for (final MapEntry(key: name, value: back) in backs.entries) {
      testWidgets(
        '$name twice with a PopScope $where should keep the app open and the '
        'page',
        (tester) async {
          _popAttempts = 0;
          _scopeAroundTabs = scopeAroundTabs;
          final router = RootStackRouter.build(
            routes: [AutoRoute(page: _tabsScreen, path: '/', children: tabs)],
          );
          addTearDown(router.dispose);
          final frameworkHandlesBack = FrameworkHandlesBackRecorder()
            ..listen(tester);
          await tester.pumpWidget(
            MaterialApp.router(
              theme: androidTheme,
              routerConfig: router.config(),
            ),
          );
          await tester.pumpAndSettle();
          final tabsRouter = router.innerRouterOf<TabsRouter>(
            _tabsScreen.name,
          )!;
          if (!scopeAroundTabs) {
            tabsRouter.setActiveIndex(1);
            await tester.pumpAndSettle();
          }
          if (pushInTab) {
            unawaited(
              tabsRouter
                  .innerRouterOf<StackRouter>(_stackTab.name)!
                  .push(const _Route('StackPage2')),
            );
            await tester.pumpAndSettle();
          }
          final page = router.topRoute.name;
          expect(frameworkHandlesBack.last, isTrue);

          for (var attempt = 1; attempt <= 2; attempt++) {
            await back(tester);
            expect(frameworkHandlesBack.last, isTrue);
            expectTopPage(router, page);
            expect(_popAttempts, attempt);
          }
        },
        skip: kIsWeb,
        // Android only: on web Flutter never tells the platform whether it
        // handles back.
      );
    }
  }
}

var _popAttempts = 0;
var _scopeAroundTabs = false;

void _countBlockedPop() => _popAttempts++;

final _tabsScreen = PageInfo(
  'TabsScreenRoute',
  builder: (_) {
    const tabs = AutoTabsRouter(routes: [_Route('TabA'), _Route('TabB')]);
    return _scopeAroundTabs
        ? const BlockedPopScope(onBlockedPop: _countBlockedPop, child: tabs)
        : tabs;
  },
);

final _stackTab = PageInfo('TabB', builder: (_) => const AutoRouter());

PageInfo _tab(String name) => .new(name, builder: (_) => Text(name));

PageInfo _guarded(String name) => .new(
  name,
  builder: (_) =>
      BlockedPopScope(onBlockedPop: _countBlockedPop, child: Text(name)),
);

class _Route extends PageRouteInfo<void> {
  const new(super.name);
}
