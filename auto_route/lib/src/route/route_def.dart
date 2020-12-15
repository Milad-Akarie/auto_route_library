import 'package:flutter/foundation.dart';

import '../auto_route_guard.dart';
import '../matcher/route_matcher.dart';

@immutable
class RouteConfig {
  final String key;
  final String path;
  final bool fullMatch;
  final Type page;
  final RoutesCollection _children;
  final String redirectTo;
  final List<AutoRouteGuard> guards;
  final bool hasParallelChildren;

  RouteConfig(
    this.key, {
    @required this.path,
    this.page,
    this.hasParallelChildren = false,
    this.guards = const [],
    this.fullMatch = false,
    this.redirectTo,
    List<RouteConfig> children,
  })  : assert(page == null || redirectTo == null),
        assert(fullMatch != null),
        assert(guards != null),
        assert(page == null || redirectTo == null),
        _children = children != null ? RoutesCollection.from(children) : null;

  bool get isSubTree => _children != null;

  RoutesCollection get children => _children;

  bool get isRedirect => redirectTo != null;
}
