import 'package:flutter/foundation.dart';

import '../auto_route_guard.dart';
import '../matcher/route_matcher.dart';
import '../utils.dart';

@immutable
class RouteDef {
  final String key;
  final String path;
  final Pattern _pattern;
  final bool fullMatch;
  final Type page;
  final RoutesCollection _children;
  final String redirectTo;
  final List<AutoRouteGuard> guards;
  final String group;

  RouteDef(
    this.key, {
    @required this.path,
    this.page,
    this.guards = const [],
    this.fullMatch = false,
    this.redirectTo,
    this.group,
    List<RouteDef> children,
  })  : assert(page == null || redirectTo == null),
        assert(fullMatch != null),
        assert(guards != null),
        assert(page == null || redirectTo == null),
        _pattern = RegexUtils.compilePattern(path, fullMatch),
        _children = children != null ? RoutesCollection.from(children) : null;

  bool get hasChildren => _children != null;

  RoutesCollection get children => _children;

  bool get isRedirect => redirectTo != null;

  Pattern get pattern => _pattern;
}
