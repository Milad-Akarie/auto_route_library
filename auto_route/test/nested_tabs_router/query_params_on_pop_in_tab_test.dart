import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// flutter/flutter#116872: after a pop, the url and the route's query params
// should be those of the page underneath, not the popped page's.
// query_params_on_pop_test.dart checks a flat stack; this is the tabs variant.
// Steps: open the shop tab's list at /shop?search=shoes, push its details
// page at /shop/details?id=7 inside the tab, then pop.
void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: _tabsScreen,
          path: '/',
          children: [
            AutoRoute(
              page: _shopTab,
              path: 'shop',
              children: [
                AutoRoute(page: _page('ShopList'), path: ''),
                AutoRoute(page: _page('ShopDetails'), path: 'details'),
              ],
            ),
            AutoRoute(page: _page('Profile'), path: 'profile'),
          ],
        ),
      ],
    );
  });

  StackRouter shopRouter() => router.innerRouterOf<TabsRouter>(_tabsScreen.name)!.innerRouterOf(_shopTab.name)!;

  Future<void> openDetails(WidgetTester tester) async {
    await pumpRouterApp(tester, router, initialLink: '/shop?search=shoes');
    expect(router.urlState.url, '/shop?search=shoes');
    await router.navigatePath('/shop/details?id=7');
    await tester.pumpAndSettle();
    expect(router.topRoute.name, 'ShopDetails');
    expect(router.urlState.url, '/shop/details?id=7');
  }

  testWidgets("pop inside a tab restores the query params of the tab's page underneath", (tester) async {
    await openDetails(tester);

    shopRouter().pop();
    await tester.pumpAndSettle();

    expect(router.topRoute.name, 'ShopList');
    expect(router.urlState.url, '/shop?search=shoes');
    expect(router.topRoute.queryParams.rawMap, {'search': 'shoes'});
  });

  testWidgets('system back inside a tab restores them too', (tester) async {
    await openDetails(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(router.topRoute.name, 'ShopList');
    expect(router.urlState.url, '/shop?search=shoes');
    expect(router.topRoute.queryParams.rawMap, {'search': 'shoes'});
  });
}

final _tabsScreen = PageInfo(
  'TabsScreen',
  builder: (_) => const AutoTabsRouter(routes: [PageRouteInfo('ShopTab'), PageRouteInfo('Profile')]),
);

final _shopTab = PageInfo('ShopTab', builder: (_) => const AutoRouter());

PageInfo _page(String name) => .new(name, builder: (_) => Text(name));
