import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/matcher/route_match.dart';
import 'package:flutter/foundation.dart';

import '../auto_route_guard.dart';
import '../matcher/route_matcher.dart';

typedef RouteBuilder<T extends PageRouteInfo> = T Function(RouteMatch match);

@immutable
class RouteConfig<T extends PageRouteInfo> {
  final String name;
  final String path;
  final bool fullMatch;
  final Type page;
  final RouteCollection _children;
  final String redirectTo;
  final List<AutoRouteGuard> guards;
  final bool usesTabsRouter;
  final RouteBuilder<T> routeBuilder;

  RouteConfig(
    this.name, {
    @required this.path,
    this.page,
    this.usesTabsRouter = false,
    this.guards = const [],
    this.fullMatch = false,
    this.redirectTo,
    this.routeBuilder,
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
