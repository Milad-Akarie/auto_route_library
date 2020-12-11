import 'dart:collection';

import 'package:auto_route/src/matcher/route_match.dart';

import '../../auto_route.dart';

class RoutesCollection {
  final LinkedHashMap<String, RouteConfig> _routesMap;

  RoutesCollection(this._routesMap)
      : assert(_routesMap != null),
        assert(_routesMap.isNotEmpty);

  factory RoutesCollection.from(List<RouteConfig> routes) {
    assert(routes != null);
    final routesMap = LinkedHashMap<String, RouteConfig>();
    routes.forEach((r) => routesMap[r.key] = r);
    return RoutesCollection(routesMap);
  }

  Iterable<RouteConfig> get routes => _routesMap.values;

  Iterable<String> get keys => _routesMap.keys;

  RouteConfig operator [](String key) => _routesMap[key];

  bool containsKey(String key) => _routesMap.containsKey(key);

  RoutesCollection subCollectionOf(String key) {
    assert(this[key]?.children != null, "$key does not have children");
    return this[key].children;
  }

  RouteConfig configWithPath(String path) {
    return routes.firstWhere((c) => c.path == path, orElse: () => null);
  }
}

class RouteMatcher {
  final RoutesCollection collection;

  const RouteMatcher(this.collection) : assert(collection != null);

  List<RouteMatch> match(String rawPath, {bool returnOnFirstMatch = false}) {
    assert(returnOnFirstMatch != null);
    return _match(Uri.parse(rawPath), collection, returnOnFirstMatch: returnOnFirstMatch);
  }

  List<RouteMatch> _match(Uri uri, RoutesCollection routesCollection, {bool returnOnFirstMatch = false}) {
    var pathSegments = split(uri.path);
    var matches = <RouteMatch>[];
    for (var def in routesCollection.routes) {
      var match = matchRoute(uri, def);
      if (match != null) {
        if (def.isRedirect) {
          var redirectMatches = _match(Uri.parse(def.redirectTo), routesCollection);
          if (redirectMatches != null && redirectMatches.length == 1) {
            return [redirectMatches.first.copyWith(segments: match.segments)];
          }
          return redirectMatches;
        }
        // has rest
        if (match.segments.length != pathSegments.length) {
          if (match.config.isSubTree) {
            var rest = uri.replace(pathSegments: pathSegments.sublist(match.segments.length));
            var children = _match(rest, match.config.children);
            if (children != null) {
              return matches..add(match.copyWith(children: children));
            } else
              continue;
          }
        } else {
          // has complete match
          return matches..add(match);
        }
        matches.add(match);
      }
      if (returnOnFirstMatch) {
        break;
      }
    }
    if (matches.isEmpty) {
      return null;
    }
    return matches;
  }

  RouteMatch matchRoute(Uri url, RouteConfig routeDef) {
    var parts = split(routeDef.path);
    var segments = split(url.path);

    if (parts.length > segments.length) {
      return null;
    }

    if (routeDef.fullMatch && segments.length > parts.length) {
      return null;
    }

    var pathParams = <String, String>{};
    for (var index = 0; index < parts.length; index++) {
      var segment = segments[index];
      var part = parts[index];
      if (part.startsWith(':')) {
        pathParams[part.substring(1)] = segment;
      } else if (segment != part && part != "*") {
        return null;
      }
    }

    var splitAt = parts.length;
    if (parts.last == "*") {
      splitAt = segments.length;
    }
    return RouteMatch(
        segments: segments.sublist(0, splitAt),
        config: routeDef,
        pathParams: pathParams,
        queryParams: url.queryParameters,
        fragment: url.fragment);
  }

  List<String> split(String path) {
    var segments = path.split('/');
    if (segments.length > 1 && segments.last.isEmpty) {
      segments.removeLast();
    }
    return segments;
  }

  bool _isValidRoute(PageRouteInfo route, RoutesCollection routes) {
    return _resolveConfig(route, routes) != null;
  }

  RouteConfig resolveConfigOrNull(PageRouteInfo route) {
    return _resolveConfig(route, collection);
  }

  RouteConfig _resolveConfig(PageRouteInfo route, RoutesCollection routes) {
    var routeConfig = routes[route.routeKey];
    if (routeConfig == null) {
      return null;
    }
    if (route.hasChildren) {
      var childrenMatch = route.children.every((r) => _isValidRoute(r, routeConfig.children));
      if (!childrenMatch) {
        return null;
      }
    }
    return routeConfig;
  }
}
