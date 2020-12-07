import 'dart:collection';

import 'package:auto_route/src/route/page_route_info.dart';
import 'package:auto_route/src/route/route_def.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../utils.dart';

class RoutesCollection {
  final LinkedHashMap<String, RouteDef> _routesMap;

  RoutesCollection(this._routesMap)
      : assert(_routesMap != null),
        assert(_routesMap.isNotEmpty);

  factory RoutesCollection.from(List<RouteDef> routes) {
    assert(routes != null);
    final routesMap = LinkedHashMap<String, RouteDef>();
    routes.forEach((r) => routesMap[r.key] = r);
    return RoutesCollection(routesMap);
  }

  Iterable<RouteDef> get routes => _routesMap.values;

  Iterable<String> get keys => _routesMap.keys;

  RouteDef operator [](String key) => _routesMap[key];

  bool containsKey(String key) => _routesMap.containsKey(key);

  RoutesCollection subCollectionOf(String key) {
    assert(this[key]?.children != null, "$key does not have children");
    return this[key].children;
  }

  RouteDef firstRouteWithPathORNull(String path) {
    return routes.firstWhere((r) => r.path == path, orElse: () => null);
  }
}

class RouteMatcher {
  final RoutesCollection collection;

  const RouteMatcher(this.collection) : assert(collection != null);

  List<RouteMatch> match(String rawPath, {bool returnOnFirstMatch = false}) {
    assert(returnOnFirstMatch != null);
    return _match(rawPath, collection, returnOnFirstMatch: returnOnFirstMatch);
  }

  List<RouteMatch> _match(String rawPath, RoutesCollection collection, {bool returnOnFirstMatch}) {
    final uri = Uri.tryParse(rawPath);
    // return early if raw path parsing fails
    if (uri == null) {
      return null;
    }

    final path = uri.path;
    final matches = <RouteMatch>[];
    for (var routeDef in collection.routes) {
      var regex = RegExp(routeDef.pattern);
      var stringMatch = regex.stringMatch(path);
      if (stringMatch == null) {
        continue;
      }
      var children = <RouteMatch>[];

      if (routeDef.isSubTree) {
        var remainingSegments = path.substring(stringMatch.length);
        var rest = uri.replace(path: remainingSegments).toString();
        var subMatches = _match(
          rest,
          routeDef.children,
          returnOnFirstMatch: returnOnFirstMatch,
        );
        if (remainingSegments.isNotEmpty && subMatches == null) {
          matches.clear();
          continue;
        }
        if (subMatches != null) {
          children.addAll(subMatches);
        }
      }

      matches.add(RouteMatch(
        key: routeDef.key,
        path: routeDef.path,
        pathName: stringMatch,
        children: children,
        pathParams: _extractPathParams(regex, stringMatch),
        queryParams: uri.queryParameters,
        fragment: uri.fragment,
      ));

      if (returnOnFirstMatch || matches.last.fullPath == path) {
        break;
      }
    }

    if (matches.isEmpty || (!returnOnFirstMatch && matches.last.fullPath != path)) {
      return null;
    }

    return matches;
  }

  Map<String, dynamic> _extractPathParams(RegExp pathReg, String path) {
    var pathMatch = pathReg.firstMatch(path);
    var params = <String, dynamic>{};
    if (pathMatch != null) {
      for (var name in pathMatch.groupNames) {
        params[name] = pathMatch.namedGroup(name);
      }
    }
    return params;
  }

  RouteDef findRouteDef(PageRouteInfo route) {
    return _getRouteDef(route, collection);
  }

  bool _hasMatch(PageRouteInfo route, RoutesCollection routes) {
    return _getRouteDef(route, routes) != null;
  }

  RouteDef _getRouteDef(PageRouteInfo route, RoutesCollection routes) {
    var def = routes[route.routeKey];
    if (def == null || !RegExp(def.pattern).hasMatch(route.pathName)) {
      return null;
    }
    if (route.hasChildren) {
      var childrenMatch = route.children.every((r) => _hasMatch(r, def.children));
      if (!childrenMatch) {
        return null;
      }
    }
    return def;
  }
}

@immutable
class RouteMatch {
  final String key;
  final String path;
  final String pathName;
  final Map<String, dynamic> pathParams;
  final Map<String, dynamic> queryParams;
  final List<RouteMatch> children;
  final String fragment;

  const RouteMatch({
    @required this.key,
    @required this.path,
    @required this.pathName,
    this.children,
    this.pathParams,
    this.queryParams,
    this.fragment,
  });

  String get fullPath => p.joinAll([path, if (hasChildren) children.last.fullPath]);

  String get segments => "$path ${hasChildren ? children.map((e) => e.segments) : ''}";

  bool get hasChildren => !listNullOrEmpty(children);

  @override
  String toString() {
    return 'RouteMatch{key: $key, path: $path, children: $children}';
  }
}
