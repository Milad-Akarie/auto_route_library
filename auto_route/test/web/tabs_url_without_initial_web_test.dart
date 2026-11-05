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
        // No tab has a '' path or is initial, so '/tabs' names no tab.
        AutoRoute(
          page: _TabsRoute.page,
          path: '/tabs',
          children: [
            AutoRoute(page: _Tab1Route.page, path: 'tab-1'),
            AutoRoute(page: _Tab2Route.page, path: 'tab-2'),
          ],
        ),
      ],
    );
    await rewindBrowserHistory();
  });

  // Found while settling the web issues; no upstream report.
  // Steps: a tabs host at '/tabs' whose tabs have no '' path and none is
  // initial. Navigate to it from '/', tap the second tab, press the browser's
  // back button, then its forward button.
  // Happened: the first tab showed at '/tabs', so going back to that entry
  // named no tab and the second tab stayed on screen.
  // Should: the entry holds '/tabs/tab-1', and each button shows the tab its
  // url names.
  for (final includePrefixMatches in [false, true]) {
    testWidgets('On web, the browser back button returns to the first tab of a host opened without a tab in its url, '
        'includePrefixMatches: $includePrefixMatches', (tester) async {
      await pumpRouterConfigApp(
        tester,
        router.config(includePrefixMatches: includePrefixMatches),
      );
      await settleBrowser(tester);
      unawaited(router.navigate(const _TabsRoute()));
      await settleBrowser(tester);
      expect(browserPath, '/tabs/tab-1');
      expect(find.text('Tab 1'), findsOneWidget);
      await tester.tap(find.text('Show tab 2'));
      await settleBrowser(tester);
      expect(browserPath, '/tabs/tab-2');

      await pressBrowserBack(tester);
      expect(
        browserPath,
        '/tabs/tab-1',
        reason: 'after pressBrowserBack(tester)',
      );
      expect(
        find.text('Tab 1'),
        findsOneWidget,
        reason: 'after pressBrowserBack(tester)',
      );
      expect(router.stack.map((p) => p.name), [
        _HomeRoute.name,
        _TabsRoute.name,
      ]);

      await browserMove(tester, () => window.history.forward());
      expect(
        browserPath,
        '/tabs/tab-2',
        reason: 'after browserMove(tester, () => window.history.forward())',
      );
      expect(find.text('Tab 2'), findsOneWidget);

      await pressBrowserBack(tester);
      await pressBrowserBack(tester);
      expect(browserPath, '/');
      expect(find.text('Home'), findsOneWidget);
    });
  }
}

abstract final class _HomeRoute {
  static const String name = 'HomeRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(body: Text('Home')),
  );
}

class _TabsRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'TabsRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => Scaffold(
      body: AutoTabsRouter(
        routes: const [_Tab1Route(), _Tab2Route()],
        builder: (context, child) => Column(
          children: [
            TextButton(
              onPressed: () => context.tabsRouter.setActiveIndex(1),
              child: const Text('Show tab 2'),
            ),
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
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => const Text('Tab 1'),
  );
}

class _Tab2Route extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'Tab2Route';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => const Text('Tab 2'),
  );
}
