import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// Reproduction for https://github.com/Milad-Akarie/auto_route_library/issues/2218
// Setup, as in the report and the issues it links (#1041, #1238, #1278): the
// app's first page holds an AutoTabsRouter whose tabs are child routes of
// that page; one tab route has a guard, like an AuthGuard on a profile tab.
// Steps: switch to the guarded tab with setActiveIndex, as a bottom bar's
// onTap does, or navigate to it, open it by url, swipe to it, or go back to
// it as the home tab.
// Happens: the guarded tab shows; its guard is never asked.
// Should: the guard is asked each time the tab is about to show, and the tab
// shows only once the guard lets it in. A rejected change keeps the tab
// that was showing, and its url.
void main() {
  setUp(() {
    _isAllowed = false;
    _decision = null;
    _guardCalls = 0;
  });

  for (final kind in _Tabs.values) {
    group('${kind.name}:', () {
      testWidgets(
        'setActiveIndex to a tab whose guard rejects keeps the current tab',
        (tester) async {
          final router = _buildRouter(kind);
          await pumpRouterApp(tester, router);
          final tabs = _tabsOf(router)..setActiveIndex(1);
          await tester.pumpAndSettle();

          expect(_guardCalls, 1);
          _expectTab(tabs, 0);
          expect(router.urlState.url, '/a');
        },
      );

      testWidgets('setActiveIndex to a tab whose guard lets it in shows it', (
        tester,
      ) async {
        _isAllowed = true;
        final router = _buildRouter(kind);
        await pumpRouterApp(tester, router);
        final tabs = _tabsOf(router)..setActiveIndex(1);
        await tester.pumpAndSettle();

        expect(_guardCalls, 1);
        _expectTab(tabs, 1);
        expect(router.urlState.url, '/b');
      });

      testWidgets(
        'navigating to a tab whose guard rejects keeps the current tab',
        (tester) async {
          final router = _buildRouter(kind);
          await pumpRouterApp(tester, router);
          final tabs = _tabsOf(router);

          unawaited(
            router.navigate(
              const NamedRoute('HomeRoute', children: [NamedRoute('TabB')]),
            ),
          );
          await tester.pumpAndSettle();

          expect(_guardCalls, 1);
          _expectTab(tabs, 0);
          expect(router.urlState.url, '/a');
        },
      );

      testWidgets(
        'opening the url of a tab whose guard rejects shows the first tab',
        (tester) async {
          final router = _buildRouter(kind);
          await pumpRouterApp(tester, router, initialLink: '/b');
          final tabs = _tabsOf(router);

          expect(_guardCalls, 1);
          _expectTab(tabs, 0);
          expect(router.urlState.url, '/a');
        },
      );

      testWidgets('opening the url of a tab whose guard lets it in shows it', (
        tester,
      ) async {
        _isAllowed = true;
        final router = _buildRouter(kind);
        await pumpRouterApp(tester, router, initialLink: '/b');
        final tabs = _tabsOf(router);

        expect(_guardCalls, 1);
        _expectTab(tabs, 1);
        expect(router.urlState.url, '/b');
      });

      testWidgets(
        'a guard that decides later keeps the current tab until it lets the '
        'tab in',
        (tester) async {
          final decision = _decision = Completer<bool>();
          final router = _buildRouter(kind);
          await pumpRouterApp(tester, router);
          final tabs = _tabsOf(router)..setActiveIndex(1);
          await tester.pumpAndSettle();
          _expectTab(tabs, 0);

          decision.complete(true);
          await tester.pumpAndSettle();

          expect(_guardCalls, 1);
          _expectTab(tabs, 1);
          expect(router.urlState.url, '/b');
        },
      );

      testWidgets(
        'a guard that redirects to a login page shows the tab after the login',
        (tester) async {
          final router = _buildRouter(kind, guard: _loginGuard);
          await pumpRouterApp(tester, router);
          final tabs = _tabsOf(router)..setActiveIndex(1);
          await tester.pumpAndSettle();
          expectTopPage(router, 'LoginRoute');

          _isAllowed = true;
          await tester.tap(find.text('LoginRoute'));
          await tester.pumpAndSettle();

          expect(router.stack.map((page) => page.routeData.name), [
            'HomeRoute',
          ]);
          _expectTab(tabs, 1);
          expect(router.urlState.url, '/b');
        },
      );

      testWidgets(
        'back to a home tab whose guard rejects is not taken by the tabs',
        (tester) async {
          _isAllowed = true;
          final router = _buildRouter(kind, guardedTab: 0, homeIndex: 0);
          await pumpRouterApp(tester, router);
          final tabs = _tabsOf(router)..setActiveIndex(1);
          await tester.pumpAndSettle();
          _expectTab(tabs, 1);

          _isAllowed = false;
          expect(await tabs.maybePop(), isFalse);
          await tester.pumpAndSettle();

          expect(_guardCalls, 1);
          _expectTab(tabs, 1);
          expect(router.urlState.url, '/b');
        },
      );

      testWidgets(
        "another tab chosen while back waits for the home tab's guard keeps "
        'the tabs',
        (tester) async {
          _isAllowed = true;
          final router = _buildRouter(kind, guardedTab: 0, homeIndex: 0);
          await pumpRouterApp(tester, router);
          final tabs = _tabsOf(router)..setActiveIndex(1);
          await tester.pumpAndSettle();

          final decision = _decision = Completer<bool>();
          final wasBackHandled = tabs.maybePop();
          tabs.setActiveIndex(2);
          await tester.pumpAndSettle();
          decision.complete(false);
          await tester.pumpAndSettle();

          expect(await wasBackHandled, isTrue);
          expect(router.stack.map((page) => page.routeData.name), [
            'HomeRoute',
          ]);
          _expectTab(tabs, 2);
          expect(router.urlState.url, '/c');
        },
      );

      if (kind != .indexedStack) {
        testWidgets(
          'swiping to a tab whose guard rejects returns to the current tab',
          (tester) async {
            final router = _buildRouter(kind);
            await pumpRouterApp(tester, router);
            final tabs = _tabsOf(router);

            await tester.fling(find.text('TabA'), const Offset(-400, 0), 1000);
            await tester.pumpAndSettle();

            expect(_guardCalls, 1);
            _expectTab(tabs, 0);
            expect(router.urlState.url, '/a');
          },
        );

        testWidgets('swiping to a tab whose guard lets it in shows it', (
          tester,
        ) async {
          _isAllowed = true;
          final router = _buildRouter(kind);
          await pumpRouterApp(tester, router);
          final tabs = _tabsOf(router);

          await tester.fling(find.text('TabA'), const Offset(-400, 0), 1000);
          await tester.pumpAndSettle();

          expect(_guardCalls, 1);
          _expectTab(tabs, 1);
          expect(router.urlState.url, '/b');
        });
      }
    });
  }
}

enum _Tabs { indexedStack, pageView, tabBar }

const _kTabNames = ['TabA', 'TabB', 'TabC'];

// Whether the tab guard lets the tab in, and how often it was asked.
var _isAllowed = false;
var _guardCalls = 0;

// When set, the tab guard waits for it to decide.
Completer<bool>? _decision;

final _guard = AutoRouteGuard.simple((resolver, _) async {
  _guardCalls++;
  if (_decision case final decision?) {
    if (await decision.future) {
      resolver.next();
    } else {
      resolver.reject();
    }
  } else {
    if (_isAllowed) {
      resolver.next();
    } else {
      resolver.reject();
    }
  }
});

final _loginGuard = AutoRouteGuard.simple((resolver, _) {
  _guardCalls++;
  if (_isAllowed) {
    resolver.next();
  } else {
    unawaited(resolver.redirectUntil(const NamedRoute('LoginRoute')));
  }
});

RootStackRouter _buildRouter(
  _Tabs kind, {
  AutoRouteGuard? guard,
  int guardedTab = 1,
  int homeIndex = -1,
}) {
  final routes = [for (final name in _kTabNames) NamedRoute<Object?>(name)];
  final host = switch (kind) {
    .indexedStack => AutoTabsRouter(routes: routes, homeIndex: homeIndex),
    .pageView => AutoTabsRouter.pageView(routes: routes, homeIndex: homeIndex),
    .tabBar => AutoTabsRouter.tabBar(routes: routes, homeIndex: homeIndex),
  };
  return RootStackRouter.build(
    routes: [
      AutoRoute(
        page: PageInfo('HomeRoute', builder: (_) => Scaffold(body: host)),
        path: '/',
        children: [
          for (final (index, name) in _kTabNames.indexed)
            AutoRoute(
              page: PageInfo(name, builder: (_) => Center(child: Text(name))),
              path: name.substring(3).toLowerCase(),
              guards: [if (index == guardedTab) guard ?? _guard],
            ),
        ],
      ),
      AutoRoute(
        page: PageInfo(
          'LoginRoute',
          builder: (data) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => data.router.root.reevaluateGuards(),
                child: const Text('LoginRoute'),
              ),
            ),
          ),
        ),
        path: '/login',
      ),
    ],
  );
}

TabsRouter _tabsOf(RootStackRouter router) =>
    router.innerRouterOf('HomeRoute')!;

// The tab at [index] is the active one, and the only one on screen.
void _expectTab(TabsRouter tabs, int index) {
  expect(tabs.activeIndex, index);
  for (final (i, name) in _kTabNames.indexed) {
    expect(
      find.text(name),
      i == index ? findsOneWidget : findsNothing,
      reason: name,
    );
  }
}
