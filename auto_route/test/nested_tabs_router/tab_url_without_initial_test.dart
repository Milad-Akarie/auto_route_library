import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

class _Route extends PageRouteInfo<void> {
  const _Route(super.name);
}

// A tabs host whose tabs have no '' path and none is initial: its url, '/tabs',
// names no tab.
RootStackRouter _router() => RootStackRouter.build(routes: [
      AutoRoute(page: PageInfo('HomeRoute', builder: (_) => const Text('Home')), path: '/'),
      AutoRoute(
        page: PageInfo(
          'TabsRoute',
          builder: (_) => AutoTabsRouter(
            routes: const [_Route('Tab1Route'), _Route('Tab2Route')],
            builder: (context, child) => Column(children: [
              TextButton(onPressed: () => context.tabsRouter.setActiveIndex(1), child: const Text('Show tab 2')),
              Expanded(child: child),
            ]),
          ),
        ),
        path: '/tabs',
        children: [
          AutoRoute(page: PageInfo('Tab1Route', builder: (_) => const Text('Tab 1')), path: 'tab-1'),
          AutoRoute(page: PageInfo('Tab2Route', builder: (_) => const Text('Tab 2')), path: 'tab-2'),
        ],
      ),
    ]);

void main() {
  // Found while settling the web issues; no upstream report.
  // Steps: a tabs host at '/tabs' whose tabs, 'tab-1' and 'tab-2', have no ''
  // path and none is initial. Navigate to it from '/', tap the second tab, then
  // go back.
  // Happened: the url stayed '/tabs' while the first tab showed, so going back
  // to that entry named no tab and the second tab stayed on screen.
  // Should: the url names the first tab, '/tabs/tab-1', and going back shows it.
  for (final includePrefixMatches in [false, true]) {
    testWidgets(
        'A tabs host opened without a tab in its url reports its first tab, '
        'includePrefixMatches: $includePrefixMatches', (tester) async {
      final router = _router();
      await pumpRouterConfigApp(tester, router.config(includePrefixMatches: includePrefixMatches));
      router.navigate(const _Route('TabsRoute'));
      await tester.pumpAndSettle();
      expect(find.text('Tab 1'), findsOneWidget);
      expect(router.currentUrl, '/tabs/tab-1');

      await tester.tap(find.text('Show tab 2'));
      await tester.pumpAndSettle();
      expect(router.currentUrl, '/tabs/tab-2');

      // On web, back moves the browser, whose history this runner doesn't
      // keep; test/web/tabs_url_without_initial_web_test.dart goes back there.
      if (kIsWeb) return;
      router.back();
      await tester.pumpAndSettle();
      expect(router.currentUrl, '/tabs/tab-1');
      expect(find.text('Tab 1'), findsOneWidget);
      expect(router.stack.map((p) => p.name), ['HomeRoute', 'TabsRoute']);

      router.back();
      await tester.pumpAndSettle();
      expect(router.currentUrl, '/');
    });
  }
}
