import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/route/auto_route_config.dart';

import '../main_router.dart';

class NestedTabsRouter extends MainRouter {
  @override
  final List<RouteDef> routes = [
    RouteDef(path: '/', page: TabsHostRoute.page, children: tabRoutes),
    RedirectRoute(path: '*', redirectTo: '/'),
  ];
}

final tabRoutes = [
  RouteDef(path: '', page: Tab1Route.page),
  RouteDef(path: 'tab2', page: Tab2Route.page, children: [
    RouteDef(path: '', page: Tab2Nested1Route.page),
    RouteDef(path: 'tab2Nested2', page: Tab2Nested2Route.page),
  ]),
  RouteDef(path: 'tab3',
      page: Tab3Route.page,
      maintainState: false,
      children: [
    RouteDef(path: '', page: Tab3Nested1Route.page),
    RouteDef(path: 'tab3Nested2', page: Tab3Nested2Route.page),
  ]),
];
