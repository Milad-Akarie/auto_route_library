import 'package:auto_route/auto_route.dart';

typedef OnNavigationFailure = void Function(NavigationFailure failure);

abstract class NavigationFailure {
  const NavigationFailure();
}

class RouteNotFoundFailure extends NavigationFailure {
  final String path;

  const RouteNotFoundFailure(this.path);

  @override
  String toString() {
    return "Failed to navigate to $path";
  }
}

class RejectedByGuardFailure extends NavigationFailure {
  final RouteMatch route;
  final AutoRouteGuard guard;

  const RejectedByGuardFailure(this.route, this.guard);

  @override
  String toString() {
    return '${route.stringMatch} rejected by guard ${guard.runtimeType}';
  }
}
