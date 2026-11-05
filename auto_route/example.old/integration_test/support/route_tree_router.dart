import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

import 'pages.dart';

/// A router with a nested ShopRoute and a redirect, and no wildcard, so an
/// unknown path fails.
RootStackRouter buildRouteTreeRouter() => .build(
  routes: [
    NamedRouteDef(
      name: 'HomeRoute',
      path: '/',
      builder: (_, _) => const TextPage('Home'),
    ),
    NamedRouteDef.shell(
      name: 'ShopRoute',
      path: '/shop',
      children: [
        NamedRouteDef(
          name: 'ProductsRoute',
          path: '',
          builder: (_, _) => const TextPage('Products'),
        ),
        NamedRouteDef(
          name: 'ProductRoute',
          path: ':id',
          builder: (_, _) => const TextPage('Product'),
        ),
      ],
    ),
    RedirectRoute(path: '/old-shop', redirectTo: '/shop'),
  ],
);

/// The tree [RouteNotFoundFailure] lists for [buildRouteTreeRouter].
const kRouteTreeOfRouteTreeRouter =
    '├─ /  HomeRoute\n'
    '├─ /shop  ShopRoute\n'
    '│  ├─ /shop  ProductsRoute\n'
    '│  └─ /shop/:id  ProductRoute\n'
    '└─ /old-shop  → /shop';
