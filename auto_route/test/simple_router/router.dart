import 'package:auto_route/auto_route.dart';

import '../main_router.dart';

class SimpleRouter extends MainRouter {
  @override
  final List<RouteDef> routes = [
    RouteDef(page: FirstRoute.page, path: '/'),
    RouteDef(page: SecondRoute.page),
    RouteDef(page: ThirdRoute.page),
    RouteDef(
      page: FourthRoute.page,
      guards: [
        AutoRouteGuard.simple((resolver, _) => resolver.next(false)),
      ],
    ),
  ];
}
