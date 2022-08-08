import 'package:auto_route/auto_route.dart';

import '../matcher/route_matcher.dart';

class RouteConfig {
  final String name;
  final String path;
  final bool fullMatch;
  final RouteCollection? _children;
  final String? redirectTo;
  final List<AutoRouteGuard> guards;
  final bool usesPathAsKey;
  final String? parent;
  final Map<String, dynamic> meta;
  final bool deferredLoading;

  RouteConfig(
    this.name, {
    required this.path,
    this.usesPathAsKey = false,
    this.guards = const [],
    this.fullMatch = false,
    this.redirectTo,
    this.parent,
    this.meta = const {},
    this.deferredLoading = false,
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
