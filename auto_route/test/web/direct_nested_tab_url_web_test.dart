@TestOn('browser')
library;

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';
import 'browser_history.dart';

void main() {
  useRealBrowserHistory();

  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/merchants',
          page: _shell('MerchantsRoute'),
          guards: const [_AllowGuard()],
          children: [
            AutoRoute(
              path: '',
              page: _page('MerchantsListRoute'),
              guards: const [_AllowGuard()],
              initial: true,
            ),
            AutoRoute(
              path: ':id',
              page: _MerchantRoute.page,
              guards: const [_AllowGuard()],
              children: [
                AutoRoute(
                  path: 'dashboard',
                  page: _page('DashboardRoute'),
                  guards: const [_AllowGuard()],
                ),
                AutoRoute(
                  path: 'purchases',
                  page: _page('PurchasesRoute'),
                  guards: const [_AllowGuard()],
                ),
                AutoRoute(
                  path: 'profile',
                  page: _page('ProfileRoute'),
                  guards: const [_AllowGuard()],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/912
  // On web, type '/merchants/m1/purchases' into the address bar: the page
  // 'merchants/:id' holds an AutoTabsRouter over dashboard, purchases and
  // profile, all behind guards.
  // Reported: the purchases page was built without its parent, which hands it
  // the id. Should: the merchant page is built first, around the purchases tab.
  testWidgets(
    'On web, a typed url of a tab of a nested page builds the page around it',
    (tester) async {
      openBrowserAt(tester, '/merchants/m1/purchases');
      await pumpRouterConfigApp(tester, router.config());
      await settleBrowser(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Merchant m1'), findsOneWidget);
      expect(find.text('PurchasesRoute'), findsOneWidget);
      expect(browserPath, '/merchants/m1/purchases');
    },
  );

  // Same setup with the url the report says worked: the first tab opens.
  testWidgets('On web, a typed url of the nested page opens its first tab', (
    tester,
  ) async {
    openBrowserAt(tester, '/merchants/m1');
    await pumpRouterConfigApp(tester, router.config());
    await settleBrowser(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Merchant m1'), findsOneWidget);
    expect(find.text('DashboardRoute'), findsOneWidget);
  });
}

class _AllowGuard extends AutoRouteGuard {
  const new();

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) =>
      resolver.next();
}

PageInfo _page(String name) => .new(name, builder: (_) => Text(name));

PageInfo _shell(String name) => .new(name, builder: (_) => const AutoRouter());

class _MerchantRoute {
  static final PageInfo page = PageInfo(
    'MerchantRoute',
    builder: (data) => Column(
      children: [
        Text('Merchant ${data.inheritedPathParams.getString('id')}'),
        const Expanded(child: AutoTabsRouter(builder: _tabsBuilder)),
      ],
    ),
  );

  static Widget _tabsBuilder(BuildContext context, Widget child) => child;
}
