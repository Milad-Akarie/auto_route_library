import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// The url after a tab switch is the page on screen in the new tab.
// https://github.com/flutter/flutter/issues/146610
// Headless test: auto_route/test/shell/url_after_tab_switch_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('url after tab switch', () {
    // Steps: tabs A and B, each with its own stack of a first and a second
    // page. Push A's second page, switch to B, push B's second page, switch
    // back to A, then to B again.
    // Should: after each switch, the url is the new tab's second page, not its
    // first, in the browser's address bar too on web.
    testWidgets(
      'After switching tabs, the url is the page on screen in the new tab',
      (tester) async {
        final router = RootStackRouter.build(
          routes: [
            AutoRoute(
              path: '/',
              page: PageInfo(
                'HomeRoute',
                builder: (_) => const AutoTabsRouter(
                  routes: [_Route('ATab'), _Route('BTab')],
                ),
              ),
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
        await pumpRouterApp(tester, router);
        final tabs = router.innerRouterOf<TabsRouter>('HomeRoute')!;

        Future<void> expectUrl(String text, String url) async {
          expect(find.text(text), findsOneWidget);
          expect(router.urlState.url, url);
          await expectBrowserUrl(url);
        }

        Future<void> showTab(int index) async {
          tabs.setActiveIndex(index);
          await tester.pumpAndSettle();
        }

        await expectUrl('A1', '/a');
        unawaited(tabs.stackRouterOfIndex(0)!.push(const _Route('A2')));
        await tester.pumpAndSettle();
        await expectUrl('A2', '/a/second');

        await showTab(1);
        await expectUrl('B1', '/b');
        unawaited(tabs.stackRouterOfIndex(1)!.push(const _Route('B2')));
        await tester.pumpAndSettle();
        await expectUrl('B2', '/b/second');

        await showTab(0);
        await expectUrl('A2', '/a/second');
        await showTab(1);
        await expectUrl('B2', '/b/second');
      },
    );
  });
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));

class _Route extends PageRouteInfo<void> {
  const new(super.name);
}
