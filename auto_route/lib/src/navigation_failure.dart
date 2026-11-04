import 'package:auto_route/auto_route.dart';

/// Signature for a function that takes a [NavigationFailure]
/// Used in [RoutingController].
typedef OnNavigationFailure = void Function(NavigationFailure failure);

/// An abstract parent type for all navigation failures
abstract class NavigationFailure {
  /// default const constructor
  const NavigationFailure();
}

/// A failure indicates that the request route or path
/// has not been found by the [RouteMatcher]
class RouteNotFoundFailure extends NavigationFailure {
  /// default constructor
  const RouteNotFoundFailure(this.path);

  /// the path or name of the target route
  final String path;

  // coverage:ignore-start
  @override
  String toString() => "Failed to navigate to $path";
  // coverage:ignore-end
}

/// A failure indicates that the one of the guards
/// has aborted the navigation on this route
/// by calling [NavigationResolver.next] with false value
class RejectedByGuardFailure extends NavigationFailure {
  /// default constructor
  const RejectedByGuardFailure(this.route, this.guard);

  /// The rejected route
  final RouteMatch route;

  /// The guard that did the rejection
  final AutoRouteGuard guard;

  // coverage:ignore-start
  @override
  String toString() => '${route.stringMatch} rejected by guard ${guard.runtimeType}';
  // coverage:ignore-end
}
