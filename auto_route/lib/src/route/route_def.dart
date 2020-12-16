import 'package:flutter/foundation.dart';

import '../auto_route_guard.dart';
import '../matcher/route_matcher.dart';

@immutable
class RouteConfig {
  final String key;
  final String path;
  final bool fullMatch;
  final Type page;
  final RouteCollection _children;
  final String redirectTo;
  final List<AutoRouteGuard> guards;
  final bool usesTabsRouter;

  RouteConfig(
    this.key, {
    @required this.path,
    this.page,
    this.usesTabsRouter = false,
    this.guards = const [],
    this.fullMatch = false,
    this.redirectTo,
    List<RouteConfig> children,
  })  : assert(page == null || redirectTo == null),
        assert(fullMatch != null),
        assert(guards != null),
        assert(page == null || redirectTo == null),
        _children = children != null ? RouteCollection.from(children) : null;

  bool get isSubTree => _children != null;

  RouteCollection get children => _children;

  bool get isRedirect => redirectTo != null;
}
