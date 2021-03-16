import 'package:auto_route/auto_route.dart';

import '../auto_route_guard.dart';
import '../matcher/route_matcher.dart';

class RouteConfig {
  final String name;
  final String path;
  final bool fullMatch;
  final RouteCollection? _children;
  final String? redirectTo;
  final List<AutoRouteGuard> guards;
  final bool usesTabsRouter;

  RouteConfig(
    this.name, {
    required this.path,
    this.usesTabsRouter = false,
    this.guards = const [],
    this.fullMatch = false,
    this.redirectTo,
    List<RouteConfig>? children,
  }) : _children = children != null ? RouteCollection.from(children) : null;

  bool get isSubTree => _children != null;

  RouteCollection? get children => _children;

  bool get isRedirect => redirectTo != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteConfig &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          path == other.path;

  @override
  int get hashCode => name.hashCode ^ path.hashCode ^ fullMatch.hashCode;

  @override
  String toString() {
    return 'RouteConfig{name: $name}';
  }
}
