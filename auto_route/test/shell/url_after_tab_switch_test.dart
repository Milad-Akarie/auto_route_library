import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/flutter/flutter/issues/146610
// Setup: tabs A and B, each with its own stack of a first and a second page.
// Steps: push A's second page, switch to B, push B's second page, switch back
// to A, then to B again.
// Should: after each switch, the url the router reports to the platform, and
// the router's own url, is the page on screen in the new tab: its second
// page, not its first.
void main() {
  testWidgets('After switching tabs, the url is the page on screen in the new tab', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('HomeRoute', builder: (_) => const AutoTabsRouter(routes: [_Route('ATab'), _Route('BTab')])),
          children: [
            for (final tab in ['A', 'B'])
              AutoRoute(
                path: tab.toLowerCase(),
                page: EmptyShellRoute('${tab}Tab'),
                children: [
                  AutoRoute(path: '', page: _page('${tab}1')),
                  AutoRoute(path: 'second', page: _page('${tab}2')),
                ],
              ),
          ],
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    final tabs = router.innerRouterOf<TabsRouter>('HomeRoute')!;

    void expectUrl(String text, String url) {
      expect(find.text(text), findsOneWidget);
      expect(router.urlState.url, url);
      expect(router.currentUrl, url);
      final provider = tester.widget<Router<Object>>(find.byType(Router<Object>)).routeInformationProvider!;
      expect(provider.value.uri.toString(), url);
    }

    Future<void> showTab(int index) async {
      tabs.setActiveIndex(index);
      await tester.pumpAndSettle();
    }

    expectUrl('A1', '/a');
    unawaited(tabs.stackRouterOfIndex(0)!.push(const _Route('A2')));
    await tester.pumpAndSettle();
    expectUrl('A2', '/a/second');

    await showTab(1);
    expectUrl('B1', '/b');
    unawaited(tabs.stackRouterOfIndex(1)!.push(const _Route('B2')));
    await tester.pumpAndSettle();
    expectUrl('B2', '/b/second');

    await showTab(0);
    expectUrl('A2', '/a/second');
    await showTab(1);
    expectUrl('B2', '/b/second');
  });
}

PageInfo _page(String name) => .new(name, builder: (_) => Scaffold(body: Text(name)));

class _Route extends PageRouteInfo<void> {
  const _Route(super.name);
}
