import 'package:auto_route/auto_route.dart';

import '../main_router.dart';

class NestedRouter extends MainRouter {
  @override
  final List<RouteDef> routes = [
    RouteDef(path: '/', page: FirstRoute.page),
    RouteDef(path: '/second', page: SecondHostRoute.page, children: [
      RouteDef(path: '', page: SecondNested1Route.page),
      RouteDef(path: 'nested2',
          page: SecondNested2Route.page,
          fullscreenDialog: true),
    ]),
    RouteDef(path: '/declarative',
        page: DeclarativeRouterHostRoute.page,
        children: [
      RouteDef(path: '', page: SecondNested1Route.page),
      RouteDef(path: 'nested2', page: SecondNested2Route.page),
      RouteDef(path: 'nested3', page: SecondNested3Route.page),
    ]),
  ];
}
