import 'package:auto_route/src/matcher/route_match.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

import '../../auto_route.dart';
import '../utils.dart';

@immutable
class PageRouteInfo {
  final String _name;
  final String path;
  final RouteMatch match;
  final Map<String, dynamic> params;
  final Map<String, dynamic> queryParams;
  final List<PageRouteInfo> initialChildren;

  const PageRouteInfo(
    this._name, {
    @required this.path,
    this.initialChildren,
    this.match,
    this.params = const {},
    this.queryParams = const {},
  });

  String get routeName => _name;

  String get stringMatch {
    if (match != null) {
      return p.joinAll(match.segments);
    }
    return _expand(path, params);
  }

  String get fullPath => p.joinAll(
      [stringMatch, if (hasInitialChildren) initialChildren.last.fullPath]);

  bool get hasInitialChildren => !listNullOrEmpty(initialChildren);

  bool get fromRedirect => match?.fromRedirect == true;

  static String _expand(String template, Map<String, dynamic> params) {
    if (mapNullOrEmpty(params)) {
      return template;
    }
    var paramsRegex = RegExp(":(${params.keys.join('|')})");
    var path = template.replaceAllMapped(paramsRegex, (match) {
      return params[match.group(1)]?.toString() ?? '';
    });
    return path;
  }

  @override
  String toString() {
    return 'Route{name: $_name, path: $path, params: $params}';
  }

  PageRouteInfo.fromMatch(this.match)
      : _name = match.config.name,
        path = match.config.path,
        params = match.pathParams?.rawMap,
        queryParams = match.queryParams?.rawMap,
        initialChildren = match.buildChildren();

// maybe?
  Future<void> show(BuildContext context) {
    return context.router.push(this);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageRouteInfo &&
          runtimeType == other.runtimeType &&
          _name == other._name &&
          path == other.path &&
          MapEquality().equals(params, other.params) &&
          MapEquality().equals(queryParams, other.queryParams);

  @override
  int get hashCode =>
      _name.hashCode ^ path.hashCode ^ params.hashCode ^ queryParams.hashCode;
}

class RouteData {
  final PageRouteInfo route;
  final RouteData parent;
  final RouteConfig config;

  const RouteData({
    this.route,
    this.parent,
    this.config,
  });

  List<RouteData> get breadcrumbs => List.unmodifiable([
        if (parent != null) ...parent.breadcrumbs,
        this,
      ]);

  static RouteData of(BuildContext context) {
    var scope = context.dependOnInheritedWidgetOfExactType<StackEntryScope>();
    assert(() {
      if (scope == null) {
        throw FlutterError(
            'RouteData operation requested with a context that does not include an RouteData.\n'
            'The context used to retrieve the RouteData must be that of a widget that '
            'is a descendant of a AutoRoutePage.');
      }
      return true;
    }());
    return scope.entry?.routeData;
  }

  T as<T extends PageRouteInfo>() {
    if (route is! T) {
      throw FlutterError(
          'Expected [${T.toString()}],  found [${route.runtimeType}]');
    }
    return route as T;
  }

  String get name => route._name;

  String get path => route.path;

  String get match => route.stringMatch;

  Parameters get pathParams => Parameters(route.params);

  Parameters get queryParams => Parameters(route.queryParams);

  String get fragment => route.match?.fragment;
}
