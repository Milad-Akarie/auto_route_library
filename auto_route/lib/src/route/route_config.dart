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
  final bool usesPathAsKey;

  RouteConfig(
    this.name, {
    required this.path,
    this.usesPathAsKey = false,
    this.guards = const [],
    this.fullMatch = false,
    this.redirectTo,
    List<RouteConfig>? children,
  }) : _children = children != null ? RouteCollection.from(children) : null;

  bool get hasSubTree => _children != null;

  RouteCollection? get children => _children;

  bool get isRedirect => redirectTo != null;

  @override
  String toString() {
    return 'RouteConfig{name: $name}';
  }
}
