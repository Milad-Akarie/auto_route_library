import 'package:auto_route/src/route/page_route_info.dart';

import 'auto_route_guard.dart';

typedef OnNavigationFailure = void Function(NavigationFailure failure);

abstract class NavigationFailure {
  const NavigationFailure();
}

class RouteNotFoundFailure extends NavigationFailure {
  final PageRouteInfo route;

  const RouteNotFoundFailure(this.route);

  @override
  String toString() {
    return "Failed to navigate to ${route.fullPath}";
  }
}

class RejectedByGuardFailure extends NavigationFailure {
  final List<PageRouteInfo> routes;
  final AutoRouteGuard guard;

  const RejectedByGuardFailure(this.routes, this.guard);

  @override
  String toString() {
    return '${routes.map((e) => e.match)} rejected by guard ${guard.runtimeType}';
  }
}
