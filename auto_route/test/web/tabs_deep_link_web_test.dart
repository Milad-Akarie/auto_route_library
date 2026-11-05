@TestOn('browser')
library;

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';
import 'browser_history.dart';

void main() {
  useRealBrowserHistory();
  tearDown(() => TestWidgetsFlutterBinding.instance.platformDispatcher.clearDefaultRouteNameTestValue());

  // https://github.com/Milad-Akarie/auto_route_library/issues/2171
  // On web, open the app at '/profile/account', inside the profile tab of an
  // AutoTabsRouter whose route has a guard, as the report does. The account
  // page should stay, and the address bar keep '/profile/account', not go
  // back to '/profile'.
  testWidgets('On web, a deep link into a tab opens the nested page and keeps it', (tester) async {
    final reevaluate = ValueNotifier(0);
    addTearDown(reevaluate.dispose);
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/profile/account';
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('LoginRoute'), path: '/login'),
        AutoRoute(
          page: _tabsPage,
          path: '/',
          initial: true,
          guards: const [_LateGuard()],
          children: [
            AutoRoute(page: _page('HomeRoute'), path: 'home'),
            AutoRoute(
              page: _shellPage('ProfileRoute'),
              path: 'profile',
              children: [
                AutoRoute(page: _page('ProfileContentRoute'), path: ''),
                AutoRoute(
                  page: _shellPage('AccountRoute'),
                  path: 'account',
                  children: [
                    AutoRoute(page: _page('AccountContentRoute'), path: ''),
                    AutoRoute(page: _page('CouponRoute'), path: 'coupon'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config(reevaluateListenable: reevaluate));
    await settleBrowser(tester);
    expect(find.text('AccountContentRoute'), findsOneWidget);
    expect(browserPath, '/profile/account');

    // The report's app rebuilds on sign-in state; reevaluate the guard.
    reevaluate.value++;
    await settleBrowser(tester);
    expect(find.text('AccountContentRoute'), findsOneWidget, reason: 'after settleBrowser(tester)');
    expect(router.urlState.url, '/profile/account');
    expect(browserPath, '/profile/account', reason: 'after settleBrowser(tester)');
  });
}

PageInfo _page(String name) => .new(name, builder: (_) => Text(name));

PageInfo _shellPage(String name) => .new(name, builder: (_) => const AutoRouter());

final _tabsPage = PageInfo(
  'AuthenticatedAppRoute',
  builder: (_) => AutoTabsRouter(
    routes: const [PageRouteInfo('HomeRoute'), PageRouteInfo('ProfileRoute')],
    builder: (_, child) => child,
  ),
);

// Lets the app in a moment later, as a guard checking sign-in does.
class _LateGuard extends AutoRouteGuard {
  const new();

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    unawaited(Future.delayed(const Duration(milliseconds: 20), () => resolver.next()));
  }
}
