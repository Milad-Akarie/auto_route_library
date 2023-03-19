import 'package:auto_route/auto_route.dart';

import '../main_router.dart';

class SimpleRouter extends MainRouter {
  @override
  final List<AutoRoute> routes = [
    AutoRoute(page: FirstRoute.page, path: '/'),
    AutoRoute(page: SecondRoute.page),
    AutoRoute(page: ThirdRoute.page),
    AutoRoute(
      page: FourthRoute.page,
      guards: [
        AutoRouteGuard.simple((resolver, _) => resolver.next(false)),
      ],
    ),
  ];
}
