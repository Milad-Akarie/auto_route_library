import 'dart:collection';

import 'package:auto_route/src/matcher/route_match.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;

import '../../auto_route.dart';

class RouteCollection {
  final LinkedHashMap<String, RouteConfig> _routesMap;

  RouteCollection(this._routesMap)
      : assert(_routesMap != null),
        assert(_routesMap.isNotEmpty);

  factory RouteCollection.from(List<RouteConfig> routes) {
    assert(routes != null);
    final routesMap = LinkedHashMap<String, RouteConfig>();
    routes.forEach((r) => routesMap[r.name] = r);
    return RouteCollection(routesMap);
  }

  Iterable<RouteConfig> get routes => _routesMap.values;

  RouteConfig operator [](String key) => _routesMap[key];

  bool containsKey(String key) => _routesMap.containsKey(key);

  RouteCollection subCollectionOf(String key) {
    assert(this[key]?.children != null, "$key does not have children");
    return this[key].children;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteCollection &&
          runtimeType == other.runtimeType &&
          MapEquality().equals(_routesMap, other._routesMap);

  @override
  int get hashCode => _routesMap.hashCode;
}

class RouteMatcher {
  final RouteCollection collection;

  const RouteMatcher(this.collection) : assert(collection != null);

  List<RouteMatch> match(String rawPath, {bool includePrefixMatches = false}) {
    assert(includePrefixMatches != null);
    return _match(
      Uri.parse(rawPath),
      collection,
      includePrefixMatches: includePrefixMatches,
      root: true,
    );
  }

  List<RouteMatch> _match(Uri uri, RouteCollection collection,
      {bool includePrefixMatches = false,
      bool root = false,
      bool fromRedirect = false}) {
    final pathSegments = p.split(uri.path);
    final matches = <RouteMatch>[];
    for (var config in collection.routes) {
      var match = matchRoute(uri, config, fromRedirect: fromRedirect);
      if (match != null) {
        if (!includePrefixMatches || config.path == '*') {
          matches.clear();
        }
        // handle redirects
        if (config.isRedirect) {
          return _handleRedirect(
            uri,
            collection,
            includePrefixMatches,
            match,
          );
        }

        if (match.segments.length != pathSegments.length) {
          // has rest
          if (config.isSubTree) {
            final rest = uri.replace(
                pathSegments: pathSegments.sublist(match.segments.length));
            final children = _match(rest, config.children,
                includePrefixMatches: includePrefixMatches);
            match = match.copyWith(children: children);
          }
          matches.add(match);
          if (match.url.length == pathSegments.length) {
            break;
          }
        } else {
          // has complete match
          //
          // include empty route if exists
          if (config.isSubTree && !match.hasChildren) {
            match = match.copyWith(
                children: _match(uri.replace(path: ''), config.children));
          }

          matches.add(match);
          break;
        }
      }
    }

    if (matches.isEmpty ||
        (root && matches.last.url.length < pathSegments.length)) {
      return null;
    }
    return matches;
  }

  List<RouteMatch> _handleRedirect(
    Uri uri,
    RouteCollection routesCollection,
    bool includePrefixMatches,
    RouteMatch match,
  ) {
    var redirectMatches = _match(
      uri.replace(path: Uri.parse(match.config.redirectTo).path),
      routesCollection,
      includePrefixMatches: includePrefixMatches,
      fromRedirect: true,
    );
    // if (redirectMatches != null && redirectMatches.length == 1) {
    //   return [
    //     redirectMatches.first.copyWith(
    //       segments: match.segments,
    //     )
    //   ];
    // }
    return redirectMatches;
  }

  RouteMatch matchRoute(Uri url, RouteConfig config,
      {bool fromRedirect = false}) {
    var parts = p.split(config.path);
    var segments = p.split(url.path);

    if (parts.length > segments.length) {
      return null;
    }

    if (config.fullMatch &&
        segments.length > parts.length &&
        (parts.isEmpty || parts.last != '*')) {
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

    var extractedSegments = segments.sublist(0, parts.length);
    if (parts.isNotEmpty && parts.last == "*") {
      extractedSegments = segments;
    }
    return RouteMatch(
        segments: extractedSegments,
        config: config,
        fromRedirect: fromRedirect,
        pathParams: Parameters(pathParams),
        queryParams: Parameters(_normalizeSingleValues(url.queryParametersAll)),
        fragment: url.fragment);
  }

  bool _isValidRoute(PageRouteInfo route, RouteCollection routes) {
    return _resolveConfig(route, routes) != null;
  }

  RouteConfig resolveConfigOrNull(PageRouteInfo route) {
    return _resolveConfig(route, collection);
  }

  RouteConfig _resolveConfig(PageRouteInfo route, RouteCollection routes) {
    var routeConfig = routes[route.routeName];
    if (routeConfig == null) {
      return null;
    }
    if (route.hasInitialChildren) {
      var childrenMatch = route.initialChildren
          .every((r) => _isValidRoute(r, routeConfig.children));
      if (!childrenMatch) {
        return null;
      }
    }
    return routeConfig;
  }

  Map<String, dynamic> _normalizeSingleValues(
      Map<String, List<String>> queryParametersAll) {
    final queryMap = <String, dynamic>{};
    for (var key in queryParametersAll.keys) {
      var list = queryParametersAll[key];
      if (list.length > 1) {
        queryMap[key] = list;
      } else if (list.isNotEmpty) {
        queryMap[key] = list.first;
      } else {
        queryMap[key] = null;
      }
    }
    return queryMap;
  }
}
