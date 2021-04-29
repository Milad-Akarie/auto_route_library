import 'dart:collection';

import 'package:auto_route/src/matcher/route_match.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;

import '../../auto_route.dart';

class RouteCollection {
  final LinkedHashMap<String, RouteConfig> _routesMap;

  RouteCollection(this._routesMap) : assert(_routesMap.isNotEmpty);

  factory RouteCollection.from(List<RouteConfig> routes) {
    final routesMap = LinkedHashMap<String, RouteConfig>();
    routes.forEach((r) => routesMap[r.name] = r);
    return RouteCollection(routesMap);
  }

  Iterable<RouteConfig> get routes => _routesMap.values;

  RouteConfig? operator [](String key) => _routesMap[key];

  bool containsKey(String key) => _routesMap.containsKey(key);

  RouteCollection subCollectionOf(String key) {
    assert(this[key]?.children != null, "$key does not have children");
    return this[key]!.children!;
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

  const RouteMatcher(this.collection);

  List<RouteMatch>? match(String rawPath, {bool includePrefixMatches = false}) {
    return _match(
      Uri.parse(rawPath),
      collection,
      includePrefixMatches: includePrefixMatches,
      root: true,
    );
  }

  List<RouteMatch>? matchUri(Uri uri, {bool includePrefixMatches = false}) {
    return _match(
      uri,
      collection,
      includePrefixMatches: includePrefixMatches,
      root: true,
    );
  }

  List<RouteMatch>? _match(Uri uri, RouteCollection collection,
      {bool includePrefixMatches = false,
      bool root = false,
      String? redirectedFrom}) {
    final pathSegments = p.split(uri.path);
    final matches = <RouteMatch>[];
    for (var config in collection.routes) {
      var match = matchRoute(uri, config, redirectedFrom: redirectedFrom);
      if (match != null) {
        if (!includePrefixMatches || config.path == '*') {
          matches.clear();
        }
        // handle redirects
        if (config.isRedirect) {
          return _handleRedirect(
            routesCollection: collection,
            includePrefixMatches: includePrefixMatches,
            redirectTo: uri.replace(path: Uri.parse(config.redirectTo!).path),
            redirectedFrom: config.path,
          );
        }

        if (match.segments.length != pathSegments.length) {
          // has rest
          if (config.isSubTree) {
            final rest = uri.replace(
                pathSegments: pathSegments.sublist(match.segments.length));
            final children = _match(rest, config.children!,
                includePrefixMatches: includePrefixMatches);
            match = match.copyWith(children: children);
          }
          matches.add(match);
          if (match.allSegments.length == pathSegments.length) {
            break;
          }
        } else {
          // has complete match
          //
          // include empty route if exists
          if (config.isSubTree && !match.hasChildren) {
            match = match.copyWith(
                children: _match(uri.replace(path: ''), config.children!));
          }

          matches.add(match);
          break;
        }
      }
    }

    if (matches.isEmpty ||
        (root && matches.last.allSegments.length < pathSegments.length)) {
      return null;
    }
    return matches;
  }

  List<RouteMatch>? _handleRedirect({
    required RouteCollection routesCollection,
    required bool includePrefixMatches,
    required Uri redirectTo,
    required String redirectedFrom,
  }) {
    var redirectMatches = _match(
      redirectTo,
      routesCollection,
      includePrefixMatches: includePrefixMatches,
      redirectedFrom: redirectedFrom,
    );
    // if(redirectMatches != null && redirectMatches.length == 1){
    //   redirectMatches = redirectMatches.map((e) => e.copyWith(segments: p.split(redirectTo.path)),).toList();
    // }
    return redirectMatches;
  }

  RouteMatch? matchRoute(Uri url, RouteConfig config,
      {String? redirectedFrom}) {
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
      path: config.path,
      routeName: config.name,
      segments: extractedSegments,
      redirectedFrom: redirectedFrom,
      pathParams: Parameters(pathParams),
      queryParams: Parameters(_normalizeSingleValues(url.queryParametersAll)),
      fragment: url.fragment,
    );
  }

  bool _isValidRoute(PageRouteInfo route, RouteCollection routes) {
    return _resolveConfig(route, routes) != null;
  }

  RouteConfig? resolveConfigOrNull(PageRouteInfo route) {
    return _resolveConfig(route, collection);
  }

  RouteConfig? _resolveConfig(PageRouteInfo route, RouteCollection routes) {
    var routeConfig = routes[route.routeName];
    if (routeConfig == null) {
      return null;
    }
    if (route.hasChildren) {
      var childrenMatch =
          route.children!.every((r) => _isValidRoute(r, routeConfig.children!));
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
      if (list!.length > 1) {
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
