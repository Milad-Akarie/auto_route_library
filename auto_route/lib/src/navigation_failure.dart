import 'package:auto_route/auto_route.dart';

/// Signature for a function that takes a [NavigationFailure]
/// Used in [RoutingController].
typedef OnNavigationFailure = void Function(NavigationFailure failure);

/// An abstract parent type for all navigation failures
abstract class NavigationFailure {
  /// default const constructor
  const new();
}

/// A failure reporting that no route matches the path or route name a
/// navigation asked for.
///
/// A router passes it to the `onFailure` callback of the navigation; without
/// one, the navigation throws a `FlutterError` with the same message. The
/// message names [path] and lists the app's routes as [routeTree], so the
/// developer sees which paths exist next to the one that matched nothing.
class RouteNotFoundFailure extends NavigationFailure {
  /// Reports [path]; [routeTree] is the app's routes from
  /// [RouteCollection.toTreeString], or null to leave them out of the message.
  const new(this.path, {this.routeTree});

  /// The path, or for a navigation to a [PageRouteInfo] the route name, that
  /// no route matches.
  final String path;

  /// The routes of the app as a tree, by full path and name, as
  /// [RouteCollection.toTreeString] lists them; null when not given.
  final String? routeTree;

  @override
  String toString() {
    final tree = routeTree;
    if (tree == null) return 'Can not navigate to $path: no route matches it.';
    return 'Can not navigate to $path: no route matches it. The routes of the app, by full path:\n$tree';
  }
}

/// A failure indicates that the one of the guards
/// has aborted the navigation on this route
/// by calling [NavigationResolver.reject]
class RejectedByGuardFailure extends NavigationFailure {
  /// default constructor
  const new(this.route, this.guard);

  /// The rejected route
  final RouteMatch<Object?> route;

  /// The guard that did the rejection
  final AutoRouteGuard guard;

  // coverage:ignore-start
  @override
  String toString() =>
      '${route.stringMatch} rejected by guard ${guard.runtimeType}';
  // coverage:ignore-end
}
