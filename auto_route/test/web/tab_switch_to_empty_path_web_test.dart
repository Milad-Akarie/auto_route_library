@TestOn('browser')
library;

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';
import 'browser_history.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/960
// Setup: a route '/admin' is initial and holds an AutoTabsRouter over the
// child routes '' (home), 'hashtags' and 'goods'.
// Steps: open '/admin', switch to the 'hashtags' tab, then back to the first
// tab with setActiveIndex(0).
// Reported: the address bar stayed at '/admin/hashtags' on the home tab, and
// the home page's RouteData.path was empty. Fixed upstream in 3.2.3.
// Should: the address bar and router.urlState.path read '/admin' on the home
// tab, '/admin/hashtags' on the other.
void main() {
  useRealBrowserHistory();

  late RootStackRouter router;
  setUp(() async {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: PageInfo(
            'AdminRoute',
            builder: (_) => Scaffold(
              body: AutoTabsRouter(
                routes: const [
                  PageRouteInfo('HomeRoute'),
                  PageRouteInfo('HashtagsRoute'),
                  PageRouteInfo('GoodsRoute'),
                ],
                builder: (context, child) => Column(
                  children: [
                    TextButton(
                      onPressed: () => context.tabsRouter.setActiveIndex(0),
                      child: const Text('Show home'),
                    ),
                    TextButton(
                      onPressed: () => context.tabsRouter.setActiveIndex(1),
                      child: const Text('Show hashtags'),
                    ),
                    Expanded(child: child),
                  ],
                ),
              ),
            ),
          ),
          path: '/admin',
          initial: true,
          children: [
            AutoRoute(page: _page('HomeRoute'), path: ''),
            AutoRoute(page: _page('HashtagsRoute'), path: 'hashtags'),
            AutoRoute(page: _page('GoodsRoute'), path: 'goods'),
          ],
        ),
      ],
    );
    await rewindBrowserHistory();
  });

  for (final includePrefixMatches in [false, true]) {
    testWidgets(
      'On web, switching back to the tab with an empty path shows its url, '
      'includePrefixMatches: $includePrefixMatches',
      (tester) async {
        await pumpRouterConfigApp(
          tester,
          router.config(includePrefixMatches: includePrefixMatches),
        );
        await settleBrowser(tester);
        void expectHomeShown() {
          expect(find.text('HomeRoute'), findsOneWidget);
          expect(router.urlState.path, '/admin');
          expect(browserPath, '/admin');
        }

        expectHomeShown();

        await tester.tap(find.text('Show hashtags'));
        await settleBrowser(tester);
        expect(find.text('HashtagsRoute'), findsOneWidget);
        expect(browserPath, '/admin/hashtags');
        expect(router.urlState.path, '/admin/hashtags');

        await tester.tap(find.text('Show home'));
        await settleBrowser(tester);
        expectHomeShown();
      },
    );
  }
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));
