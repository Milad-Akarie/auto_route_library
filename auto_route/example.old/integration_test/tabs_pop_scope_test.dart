import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A PopScope in tabs on the app's first page keeps taking system back.
// https://github.com/Milad-Akarie/auto_route_library/issues/2023, the setups
// its comments report.
// Headless test: auto_route/test/nested_tabs_router/pop_scope_tabs_test.dart
//
// Setup: the app's first page holds an AutoTabsRouter, and a
// PopScope(canPop: false) sits around that tabs screen, on the active tab's
// page, or on a page pushed into a stack router inside a tab.
// Steps: press system back twice. On Android that goes through the
// activity, which Android calls only while Flutter says it handles back
// (see systemBack).
// Reported: PopScope heard the first back; the second closed the app.
// Should: the page stays and PopScope hears both.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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

  for (final MapEntry(key: where, value: (tabs, :scopeAroundTabs, :pushInTab))
      in setups.entries) {
    testWidgets(
      'system back twice with a PopScope $where keeps the app open and the '
      'page',
      (tester) async {
        _popAttempts = 0;
        _scopeAroundTabs = scopeAroundTabs;
        final router = RootStackRouter.build(
          routes: [AutoRoute(page: _tabsScreen, path: '/', children: tabs)],
        );
        await pumpRouterApp(tester, router);
        final tabsRouter = router.innerRouterOf<TabsRouter>(_tabsScreen.name)!;
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

        for (var attempt = 1; attempt <= 2; attempt++) {
          await systemBack(tester);
          expectTopPage(router, page);
          expect(_popAttempts, attempt);
        }
      },
    );
  }
}

var _popAttempts = 0;
var _scopeAroundTabs = false;

Widget _popScope(Widget child) => PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, _) {
    if (!didPop) _popAttempts++;
  },
  child: child,
);

final _tabsScreen = PageInfo(
  'TabsScreenRoute',
  builder: (_) {
    const tabs = AutoTabsRouter(routes: [_Route('TabA'), _Route('TabB')]);
    return _scopeAroundTabs ? _popScope(tabs) : tabs;
  },
);

final _stackTab = PageInfo('TabB', builder: (_) => const AutoRouter());

PageInfo _tab(String name) => .new(name, builder: (_) => Text(name));

PageInfo _guarded(String name) =>
    .new(name, builder: (_) => _popScope(Text(name)));

class _Route extends PageRouteInfo<void> {
  const new(super.name);
}
