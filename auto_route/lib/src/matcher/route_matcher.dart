import 'package:auto_route/src/utils.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as p;

import '../../auto_route.dart';

class RouteCollection {
  final Map<String, AutoRoute> _routesMap;

  RouteCollection(this._routesMap) : assert(_routesMap.isNotEmpty);

  factory RouteCollection.from(List<AutoRoute> routes, {bool root = false}) {
    // final checkedRoutes = <AutoRoute>[];
    // for (var route in routes) {
    //   assert(
    //     (checkedRoutes.any((r) => r.name == route.name && r.path != route.path)),
    //     'Duplicate route names must have the same path! (name: ${route.name}, path: ${route.path})\nNote: Unless specified, route name is generated from page name.',
    //   );
    //   checkedRoutes.add(route);
    // }

    final routesMap = <String, AutoRoute>{};

    for (var r in routes) {
      throwIf(
        !root && r.path.startsWith('/'),
        'Sub-paths can not start with a "/"',
      );

      routesMap[r.name] = r;
    }

    return RouteCollection(routesMap);
  }

  Iterable<AutoRoute> get routes => _routesMap.values;

  AutoRoute? operator [](String key) => _routesMap[key];

  bool containsKey(String key) => _routesMap.containsKey(key);

  RouteCollection subCollectionOf(String key) {
    assert(this[key]?.children != null, "$key does not have children");
    return this[key]!.children!;
  }

  List<AutoRoute> findPathTo(String routeName) {
    final track = <AutoRoute>[];
    for (final route in routes) {
      if (_findPath(route, routeName, track)) {
        break;
      }
    }
    return track;
  }

  bool _findPath(AutoRoute node, String routeName, List<AutoRoute> track) {
    if (node.name == routeName) {
      track.add(node);
      return true;
    }

    if (node.hasSubTree) {
      for (AutoRoute child in node.children!.routes) {
        if (_findPath(child, routeName, track)) {
          track.insert(0, node);
          return true;
        }
      }
    }

    return false;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteCollection &&
          runtimeType == other.runtimeType &&
          const MapEquality().equals(_routesMap, other._routesMap);

  @override
  int get hashCode => const MapEquality().hash(_routesMap);
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
    final pathSegments = _split(uri.path);
    final matches = <RouteMatch>[];
    for (var config in collection.routes) {
      var match = matchByPath(uri, config, redirectedFrom: redirectedFrom);
      if (match != null) {
        if (!includePrefixMatches || config.path == '*') {
          matches.clear();
        }
        // handle redirects
        if (config.isRedirect) {
          return _handleRedirect(
            routesCollection: collection,
            includePrefixMatches: includePrefixMatches,
            redirectTo: uri.replace(
                path: Uri.parse(
              PageRouteInfo.expandPath(
                config.redirectTo!,
                match.pathParams.rawMap,
              ),
            ).path),
            redirectedFrom: config.path,
          );
        }

        if (match.segments.length != pathSegments.length) {
          // has rest
          if (config.hasSubTree) {
            final rest = uri.replace(
                pathSegments: pathSegments.sublist(match.segments.length));
            final children = _match(rest, config.children!,
                includePrefixMatches: includePrefixMatches);
            match = match.copyWith(children: children);
          }
          matches.add(match);
          if (match.allSegments().length >= pathSegments.length) {
            break;
          }
        } else {
          // has complete match
          //
          // include empty route if exists
          if (config.hasSubTree && !match.hasChildren) {
            match = match.copyWith(
                children: _match(uri.replace(path: ''), config.children!));
          }

          matches.add(match);
          break;
        }
      }
    }

    if (matches.isEmpty ||
        (root &&
            matches.last.allSegments(includeEmpty: true).length <
                pathSegments.length)) {
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
    return _match(
      redirectTo,
      routesCollection,
      includePrefixMatches: includePrefixMatches,
      redirectedFrom: redirectedFrom,
    );
  }

  List<String> _split(String path) => p.split(path);

  RouteMatch? matchByPath(Uri url, AutoRoute config, {String? redirectedFrom}) {
    var parts = _split(config.path);
    var segments = _split(url.path);

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

    final stringMatch = p.joinAll(extractedSegments);
    return RouteMatch(
      path: config.path,
      name: config.name,
      meta: config.meta,
      isBranch: config.hasSubTree,
      key: ValueKey(config.usesPathAsKey ? stringMatch : config.name),
      stringMatch: stringMatch,
      segments: extractedSegments,
      redirectedFrom: redirectedFrom,
      guards: config.guards,
      pathParams: Parameters(pathParams),
      queryParams: Parameters(_normalizeSingleValues(url.queryParametersAll)),
      fragment: url.fragment,
      type: config.type,
      title: config.title,
    );
  }

  RouteMatch? matchByRoute(PageRouteInfo route) {
    return _matchByRoute(route, collection);
  }

  RouteMatch? _matchByRoute(PageRouteInfo route, RouteCollection routes) {
    var config = routes[route.routeName];
    if (config == null) {
      return null;
    }
    var childMatches = <RouteMatch>[];
    if (config.hasSubTree) {
      final subRoutes = routes.subCollectionOf(route.routeName);
      if (route.hasChildren) {
        for (var childRoute in route.initialChildren!) {
          var match = _matchByRoute(childRoute, subRoutes);
          if (match == null) {
            return null;
          } else {
            childMatches.add(match);
          }
        }
      } else {
        // include default matches if exist
        final defaultMatches = _match(Uri(path: ''), subRoutes);
        if (defaultMatches != null) {
          childMatches.addAll(defaultMatches);
        }
      }
    } else if (route.hasChildren) {
      return null;
    }
    final stringMatch =
        PageRouteInfo.expandPath(config.path, route.rawPathParams);
    return RouteMatch(
      name: route.routeName,
      segments: _split(stringMatch),
      path: config.path,
      args: route.args,
      meta: config.meta,
      key: ValueKey(
        config.usesPathAsKey ? stringMatch : route.routeName,
      ),
      isBranch: config.hasSubTree,
      guards: config.guards,
      stringMatch: stringMatch,
      fragment: route.fragment,
      redirectedFrom: route.redirectedFrom,
      children: childMatches,
      pathParams: Parameters(route.rawPathParams),
      queryParams: Parameters(route.rawQueryParams),
      type: config.type,
      title: config.title,
    );
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
