import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/flutter/flutter/issues/158238
// Setup: tabs A and B; tab B has its own stack of page B and a detail page.
// Steps: open tab B, navigate to its detail page; from the detail page, pop
// it and, in the same call, navigate to tab A; open tab B again and navigate
// to the detail page again.
// Should: tab B shows page B when reopened, and the detail page shows the
// second time.
void main() {
  for (final (how, toDetail, toA) in [
    (
      'paths',
      (RoutingController router) => router.navigatePath('/b/detail'),
      (RoutingController router) => router.navigatePath('/a'),
    ),
    (
      'routes',
      (RoutingController router) =>
          router.navigate(const _Route('DetailRoute')),
      (RoutingController router) => router.navigate(const _Route('ARoute')),
    ),
  ]) {
    testWidgets(
      'After popping and leaving a tab, navigating by $how to its detail page '
      'shows it',
      (tester) async {
        final router = RootStackRouter.build(
          routes: [
            AutoRoute(
              path: '/',
              page: PageInfo(
                'HomeRoute',
                builder: (_) => const AutoTabsRouter(
                  routes: [_Route('ARoute'), _Route('BTab')],
                ),
              ),
              children: [
                AutoRoute(path: 'a', page: _page('ARoute')),
                AutoRoute(
                  path: 'b',
                  page: const EmptyShellRoute('BTab'),
                  children: [
                    AutoRoute(path: '', page: _page('BRoute')),
                    AutoRoute(path: 'detail', page: _page('DetailRoute')),
                  ],
                ),
              ],
            ),
          ],
        );
        await pumpRouterApp(tester, router);
        final tabs = router.innerRouterOf<TabsRouter>('HomeRoute')!
          ..setActiveIndex(1);
        await tester.pumpAndSettle();
        expect(find.text('BRoute'), findsOneWidget);
        unawaited(toDetail(tester.element(find.text('BRoute')).router));
        await tester.pumpAndSettle();
        expect(find.text('DetailRoute'), findsOneWidget);

        final detailRouter = tester.element(find.text('DetailRoute')).router
          ..pop();
        unawaited(toA(detailRouter));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('ARoute'), findsOneWidget);
        expect(tabs.activeIndex, 0);

        tabs.setActiveIndex(1);
        await tester.pumpAndSettle();
        expect(
          find.text('BRoute'),
          findsOneWidget,
          reason: 'after tabs.setActiveIndex(1)',
        );
        expect(tabs.stackRouterOfIndex(1)!.stack.map((page) => page.name), [
          'BRoute',
        ]);

        unawaited(toDetail(tester.element(find.text('BRoute')).router));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'after toDetail(tester.element(find.text(BRoute)).router))',
        );
        expect(
          find.text('DetailRoute'),
          findsOneWidget,
          reason: 'after toDetail(tester.element(find.text(BRoute)).router))',
        );
        expect(router.urlState.url, '/b/detail');
      },
    );
  }
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));

class _Route extends PageRouteInfo<void> {
  const new(super.name);
}
