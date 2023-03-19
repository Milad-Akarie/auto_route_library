import 'package:auto_route/auto_route.dart';

typedef OnNavigationFailure = void Function(NavigationFailure failure);

abstract class NavigationFailure {
  const NavigationFailure();
}

class RouteNotFoundFailure extends NavigationFailure {
  final String path;

  const RouteNotFoundFailure(this.path);

  // coverage:ignore-start
  @override
  String toString() => "Failed to navigate to $path";
// coverage:ignore-end
}

class RejectedByGuardFailure extends NavigationFailure {
  final RouteMatch route;
  final AutoRouteGuard guard;

  const RejectedByGuardFailure(this.route, this.guard);

  // coverage:ignore-start
  @override
  String toString() =>
      '${route.stringMatch} rejected by guard ${guard.runtimeType}';
// coverage:ignore-end
}
