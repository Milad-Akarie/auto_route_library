import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/1303
// The report has two sentences and no code. Assumed: an AutoTabsRouter whose
// tabs each read the query parameter 'id'; the first tab is marked initial.
// The reporter fixed it by removing initial.
// Steps: open the tabs host with '?id=7', by link and by navigate with the
// parameter on the first tab's route.
// Reported: the first tab read null; the other tabs read the value.
// Should: every tab, the first included, reads '7'.
RootStackRouter _router() {
  return RootStackRouter.build(
    routes: [
      AutoRoute(
        path: '/tabs',
        page: PageInfo(
          'TabsRoute',
          builder: (_) => AutoTabsRouter(
            routes: const [
              PageRouteInfo('FirstRoute'),
              PageRouteInfo('SecondRoute'),
            ],
            builder: (context, child) => Column(
              children: [
                TextButton(
                  onPressed: () => context.tabsRouter.setActiveIndex(1),
                  child: const Text('second tab'),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
        children: [
          AutoRoute(
            path: 'first',
            initial: true,
            page: PageInfo(
              'FirstRoute',
              builder: (_) => Builder(
                builder: (context) => Text(
                  'FirstRoute id ${context.routeData.queryParams.optString('id') ?? 'null'}',
                ),
              ),
            ),
          ),
          AutoRoute(
            path: 'second',
            page: PageInfo(
              'SecondRoute',
              builder: (_) => Builder(
                builder: (context) => Text(
                  'SecondRoute id ${context.routeData.queryParams.optString('id') ?? 'null'}',
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

void main() {
  testWidgets('the first tab reads a query parameter from the link', (
    tester,
  ) async {
    final router = _router();
    await pumpRouterApp(tester, router, initialLink: '/tabs?id=7');
    expect(find.text('FirstRoute id 7'), findsOneWidget);
  });

  testWidgets('the first tab reads a query parameter from navigate', (
    tester,
  ) async {
    final router = _router();
    await pumpRouterApp(tester, router, initialLink: '/tabs/second?id=7');
    unawaited(
      router.navigate(
        const PageRouteInfo(
          'TabsRoute',
          initialChildren: [
            PageRouteInfo('FirstRoute', rawQueryParams: {'id': '7'}),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('FirstRoute id 7'), findsOneWidget);
  });
}
