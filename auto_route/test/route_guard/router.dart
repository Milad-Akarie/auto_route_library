import 'package:auto_route/auto_route.dart';

import '../main_router.dart';

class GuardTestRouter extends MainRouter {
  GuardTestRouter({
    required this.firstRouteGuard,
    required this.secondRouteGuard,
  });

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          page: FirstRoute.page,
          path: '/',
          guards: [firstRouteGuard],
        ),
        AutoRoute(
          page: SecondRoute.page,
          guards: [secondRouteGuard],
        ),
      ];

  final AutoRouteGuard firstRouteGuard;

  final AutoRouteGuard secondRouteGuard;
}
