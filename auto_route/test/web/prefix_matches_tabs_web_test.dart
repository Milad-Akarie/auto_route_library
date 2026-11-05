@TestOn('browser')
library;

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:web/web.dart' show window;

import '../router_test_utils.dart';
import 'browser_history.dart';

void main() {
  useRealBrowserHistory();

  late RootStackRouter router;
  setUp(() async {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _HomeRoute.page, path: '/'),
        AutoRoute(
          page: _TabsRoute.page,
          path: '/tabs',
          children: [
            AutoRoute(page: _Tab1Route.page, path: 'tab-1', initial: true),
            AutoRoute(page: _Tab2Route.page, path: 'tab-2'),
          ],
        ),
      ],
    );
    await rewindBrowserHistory();
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/1669
  // With includePrefixMatches, the browser's back and forward buttons changed
  // the url between /tabs/tab-1 and /tabs/tab-2 but left the tab as it was.
  // Steps, as in the reporter's app: navigate from '/' to the tabs page, tap
  // the second tab, press the browser's back button, then its forward button.
  // Should: each button shows the tab its url names.
  testWidgets('With includePrefixMatches on web, the browser back and forward buttons switch tabs', (tester) async {
    await pumpRouterConfigApp(tester, router.config(includePrefixMatches: true));
    await settleBrowser(tester);
    unawaited(router.navigate(const _TabsRoute()));
    await settleBrowser(tester);
    expect(browserPath, '/tabs/tab-1');
    await tester.tap(find.text('Show tab 2'));
    await settleBrowser(tester);
    expect(browserPath, '/tabs/tab-2');
    expect(find.text('Tab 2'), findsOneWidget);

    await pressBrowserBack(tester);
    expect(browserPath, '/tabs/tab-1', reason: 'after pressBrowserBack(tester)');
    expect(find.text('Tab 1'), findsOneWidget);
    expect(router.stack.map((p) => p.name), [_HomeRoute.name, _TabsRoute.name]);

    await browserMove(tester, () => window.history.forward());
    expect(browserPath, '/tabs/tab-2', reason: 'after browserMove(tester, () => window.history.forward())');
    expect(find.text('Tab 2'), findsOneWidget, reason: 'after browserMove(tester, () => window.history.forward())');
  });
}

class _HomeRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'HomeRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text('Home')));
}

class _TabsRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'TabsRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => Scaffold(
      body: AutoTabsRouter.tabBar(
        routes: const [_Tab1Route(), _Tab2Route()],
        builder: (context, child, tabController) => Column(
          children: [
            TextButton(onPressed: () => tabController.animateTo(1), child: const Text('Show tab 2')),
            Expanded(child: child),
          ],
        ),
      ),
    ),
  );
}

class _Tab1Route extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'Tab1Route';
  static PageInfo page = PageInfo(name, builder: (_) => const Text('Tab 1'));
}

class _Tab2Route extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'Tab2Route';
  static PageInfo page = PageInfo(name, builder: (_) => const Text('Tab 2'));
}
