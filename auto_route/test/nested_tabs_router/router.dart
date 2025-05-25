import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/route/auto_route_config.dart';

import '../main_router.dart';

class NestedTabsRouter extends MainRouter {
  @override
  final List<AutoRoute> routes = [
    AutoRoute(path: '/', page: TabsHostRoute.page, children: tabRoutes),
    RedirectRoute(path: '*', redirectTo: '/'),
  ];
}

final tabRoutes = [
  AutoRoute(path: '', page: Tab1Route.page),
  AutoRoute(path: 'tab2', page: Tab2Route.page, children: [
    AutoRoute(path: '', page: Tab2Nested1Route.page),
    AutoRoute(path: 'tab2Nested2', page: Tab2Nested2Route.page),
  ]),
  AutoRoute(path: 'tab3', page: Tab3Route.page, maintainState: false, children: [
    AutoRoute(path: '', page: Tab3Nested1Route.page),
    AutoRoute(path: 'tab3Nested2', page: Tab3Nested2Route.page),
  ]),
];
