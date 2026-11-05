import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/338, and in
// go_router flutter/flutter#120382 and flutter/flutter#127957.
// Steps: an app with nested routes, a tabs router and a redirect; push a path
// or a route no router has.
// Reported: the error says only "Can not navigate to <path>", so the developer
// can't see which paths the app has.
// Should: the failure and the error name what was asked for and list every
// route as a tree, by full path and name.
void main() {
  RootStackRouter buildRouter() => .build(
    routes: [
      AutoRoute(
        page: PageInfo('HomeRoute', builder: (_) => const Text('Home')),
        path: '/',
      ),
      AutoRoute(
        page: PageInfo('ShopRoute', builder: (_) => const AutoRouter()),
        path: '/shop',
        children: [
          AutoRoute(
            page: PageInfo('ProductsRoute', builder: (_) => const Text('Products')),
            path: '',
          ),
          AutoRoute(
            page: PageInfo('ProductRoute', builder: (_) => const Text('Product')),
            path: ':id',
          ),
        ],
      ),
      AutoRoute(
        page: PageInfo(
          'TabsRoute',
          builder: (_) => const AutoTabsRouter(routes: [PageRouteInfo('FeedRoute'), PageRouteInfo('ProfileRoute')]),
        ),
        path: '/tabs',
        children: [
          AutoRoute(
            page: PageInfo('FeedRoute', builder: (_) => const Text('Feed')),
            path: 'feed',
          ),
          AutoRoute(
            page: PageInfo('ProfileRoute', builder: (_) => const Text('Profile')),
            path: 'profile',
          ),
        ],
      ),
      RedirectRoute(path: '/old-shop', redirectTo: '/shop'),
    ],
  );

  const tree =
      '├─ /  HomeRoute\n'
      '├─ /shop  ShopRoute\n'
      '│  ├─ /shop  ProductsRoute\n'
      '│  └─ /shop/:id  ProductRoute\n'
      '├─ /tabs  TabsRoute\n'
      '│  ├─ /tabs/feed  FeedRoute\n'
      '│  └─ /tabs/profile  ProfileRoute\n'
      '└─ /old-shop  → /shop';

  test('the route collection lists its routes as a tree by full path', () {
    expect(buildRouter().routeCollection.toTreeString(), tree);
  });

  testWidgets('an unknown path reports the path and the route tree', (tester) async {
    final router = buildRouter();
    await pumpRouterApp(tester, router);
    final failures = <NavigationFailure>[];
    unawaited(router.pushPath('/shop/1/reviews', onFailure: failures.add));
    await tester.pumpAndSettle();
    final failure = failures.single as RouteNotFoundFailure;
    expect(failure.path, '/shop/1/reviews');
    expect(failure.toString(), allOf(contains('/shop/1/reviews'), contains(tree)));

    Object? error;
    try {
      await router.pushPath('/shop/1/reviews');
      // The router reports an unknown path with this error.
      // ignore: avoid_catching_errors
    } on FlutterError catch (e) {
      error = e;
    }
    expect(error?.toString(), allOf(contains('/shop/1/reviews'), contains(tree)));
  });

  testWidgets('an unknown route reports its name and the route tree', (tester) async {
    final router = buildRouter();
    await pumpRouterApp(tester, router);
    final failures = <NavigationFailure>[];
    unawaited(router.push(const PageRouteInfo('CartRoute'), onFailure: failures.add));
    await tester.pumpAndSettle();
    expect(failures.single.toString(), allOf(contains('CartRoute'), contains(tree)));

    Object? error;
    try {
      await router.push(const PageRouteInfo('CartRoute'));
      // The router reports an unknown route with this error.
      // ignore: avoid_catching_errors
    } on FlutterError catch (e) {
      error = e;
    }
    expect(error?.toString(), allOf(contains('CartRoute'), contains(tree)));
  });
}
