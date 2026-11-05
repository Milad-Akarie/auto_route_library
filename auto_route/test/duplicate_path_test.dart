import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

PageInfo _page(String name) => .new(name, builder: (_) => Text(name));

/// Reads the routes of a router built from [routes], which is what checks them.
Object _routeCollectionFor(List<AutoRoute> routes) {
  final router = RootStackRouter.build(routes: routes);
  addTearDown(router.dispose);
  return router.routeCollection;
}

/// A FlutterError, which is what the router throws for a route table it can't use, whose text matches [text].
Matcher _errorText(Object text) => isA<FlutterError>().having((e) => e.toString(), 'message', text);

void main() {
  // flutter/flutter#190741 asked go_router_builder to report two routes with
  // the same path. In auto_route the first route matched and the second
  // could never be opened by its url, with no word about it. The generator
  // can't see paths, which the app writes in its route list, so the router
  // reports it when it reads that list, in debug builds.
  group('two routes with the same path (flutter/flutter#190741)', () {
    test('fail naming both routes and the path', () {
      expect(
        () => _routeCollectionFor([
          AutoRoute(page: _page('HomeRoute'), path: '/'),
          AutoRoute(page: _page('FirstRoute'), path: '/a'),
          AutoRoute(page: _page('SecondRoute'), path: '/a'),
        ]),
        throwsA(
          _errorText(
            'FirstRoute and SecondRoute have the same path, /a, so a link to it opens only FirstRoute. '
            'Give one of them another path.',
          ),
        ),
      );
    });

    test('fail when only the param names differ', () {
      expect(
        () => _routeCollectionFor([
          AutoRoute(page: _page('MealRoute'), path: '/meal/:id'),
          AutoRoute(page: _page('MealDetailsRoute'), path: '/meal/:mealId'),
        ]),
        throwsA(_errorText(contains('MealRoute, /meal/:id, and MealDetailsRoute, /meal/:mealId, have the same path'))),
      );
    });

    test('fail across levels, where a nested path adds up to the same full path', () {
      expect(
        () => _routeCollectionFor([
          AutoRoute(
            page: _page('ShopRoute'),
            path: '/shop',
            children: [AutoRoute(page: _page('CartRoute'), path: 'cart')],
          ),
          AutoRoute(page: _page('OtherCartRoute'), path: '/shop/cart'),
        ]),
        throwsA(_errorText(contains('CartRoute and OtherCartRoute have the same path, /shop/cart'))),
      );
    });

    test('fail for two children of a shell with no path of its own', () {
      expect(
        () => _routeCollectionFor([
          AutoRoute(
            page: _page('ShellRoute'),
            path: '/',
            children: [
              AutoRoute(page: _page('FeedRoute'), path: 'feed'),
              AutoRoute(page: _page('OtherFeedRoute'), path: 'feed'),
            ],
          ),
        ]),
        throwsA(_errorText(contains('FeedRoute and OtherFeedRoute have the same path, /feed'))),
      );
    });

    // A parent and its empty-path child share a url by design: the child is
    // the page the parent shows first.
    test('are fine for a parent and its empty-path child, and for paths that differ', () {
      expect(
        () => _routeCollectionFor([
          AutoRoute(
            page: _page('ShopRoute'),
            path: '/shop',
            children: [
              AutoRoute(page: _page('ShopHomeRoute'), path: ''),
              AutoRoute(page: _page('CartRoute'), path: 'cart'),
            ],
          ),
          AutoRoute(page: _page('ItemRoute'), path: '/item/:id'),
          AutoRoute(page: _page('ItemsRoute'), path: '/item/:id?'),
          AutoRoute(page: _page('AnyRoute'), path: '*'),
        ]),
        returnsNormally,
      );
    });

    // A redirect first sends the url elsewhere while the route's children
    // stay reachable; a redirect after the route would never run.
    test('are fine for a redirect before a route with its path, not after it', () {
      final child = AutoRoute(page: _page('SchoolsRoute'), path: 'schools');
      expect(
        () => _routeCollectionFor([
          RedirectRoute(path: '/explore', redirectTo: '/explore/schools'),
          AutoRoute(page: _page('ExploreRoute'), path: '/explore', children: [child]),
        ]),
        returnsNormally,
      );
      expect(
        () => _routeCollectionFor([
          AutoRoute(page: _page('ExploreRoute'), path: '/explore', children: [child]),
          RedirectRoute(path: '/explore', redirectTo: '/explore/schools'),
        ]),
        throwsA(
          _errorText(
            contains('ExploreRoute and the redirect from /explore to /explore/schools have the same path, /explore'),
          ),
        ),
      );
    });

    // MaterialApp.router asks for the config first, so the app fails before
    // its first frame.
    test('fail when the app asks for the router config', () {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(page: _page('FirstRoute'), path: '/'),
          AutoRoute(page: _page('SecondRoute'), path: '/'),
        ],
      );
      addTearDown(router.dispose);
      expect(
        router.config,
        throwsA(
          isA<FlutterError>().having(
            (e) => e.message,
            'message',
            contains('FirstRoute and SecondRoute have the same path, /'),
          ),
        ),
      );
    });
  });
}
