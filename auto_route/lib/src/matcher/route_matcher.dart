import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as p;

/// Matches paths and [PageRouteInfo]s with
/// the given [collection]
class RouteMatcher {
  /// The list of route-entries to match against
  final RouteCollection collection;

  /// Default constructor
  const RouteMatcher(this.collection);

  /// Parses a [Uri] from [rawPath] then maps call to [_match]
  List<RouteMatch>? match(String rawPath, {bool includePrefixMatches = false}) {
    return _match(
      Uri.parse(rawPath),
      collection,
      includePrefixMatches: includePrefixMatches,
      root: true,
    );
  }

  /// Matches a uri against the config-entries in [collection]
  ///
  /// if [includePrefixMatches] is true prefixed matches
  /// will be included in the return list
  ///
  /// returns null if not match is found
  List<RouteMatch>? matchUri(Uri uri, {bool includePrefixMatches = false}) {
    return _match(
      uri,
      collection,
      includePrefixMatches: includePrefixMatches,
      root: true,
    );
  }

  List<RouteMatch>? _match(Uri uri, RouteCollection collection,
      {bool includePrefixMatches = false, bool root = false, String? redirectedFrom}) {
    final pathSegments = _split(uri.path);
    final matches = <RouteMatch>[];
    for (var config in collection.routes) {
      var match = matchByPath(uri, config, redirectedFrom: redirectedFrom);
      if (match != null) {
        if (!includePrefixMatches || config.path == '*') {
          matches.clear();
        }
        // handle redirects
        if (config is RedirectRoute) {
          final redirectToUri = Uri.parse(PageRouteInfo.expandPath(
            config.redirectTo,
            match.params.rawMap,
          ));
          return _handleRedirect(
            routesCollection: collection,
            includePrefixMatches: includePrefixMatches,
            redirectTo: redirectToUri.replace(
              queryParameters: {
                ...redirectToUri.queryParametersAll,
                ...uri.queryParametersAll,
              },
              fragment: uri.fragment,
            ),
            redirectedFrom: PageRouteInfo.expandPath(
              config.path,
              match.params.rawMap,
            ),
          );
        }

        if (match.segments.length != pathSegments.length) {
          // has rest
          if (config.hasSubTree) {
            final rest = uri.replace(
              pathSegments: pathSegments.sublist(match.segments.length).map(Uri.decodeComponent),
            );
            final children = _match(
              rest,
              collection.subCollectionOf(config.name),
              includePrefixMatches: includePrefixMatches,
            );
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
            match = match.copyWith(children: _match(uri.replace(path: ''), collection.subCollectionOf(config.name)));
          }

          matches.add(match);
          break;
        }
      }
    }

    if (matches.isEmpty || (root && matches.last.allSegments(includeEmpty: true).length < pathSegments.length)) {
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

  /// Matches a uri against a route-config [AutoRoute]
  /// and returns a single match result
  ///
  /// returns null if not match is found
  RouteMatch? matchByPath(Uri uri, AutoRoute config, {String? redirectedFrom}) {
    var parts = _split(config.path);
    var segments = _split(Uri.decodeComponent(uri.path));

    if (parts.length > segments.length) {
      return null;
    }

    if (config.fullMatch && segments.length > parts.length && (parts.isEmpty || parts.last != '*')) {
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
      config: config,
      key: ValueKey(config.usesPathAsKey ? stringMatch : config.name),
      stringMatch: stringMatch,
      segments: extractedSegments,
      redirectedFrom: redirectedFrom,
      params: Parameters(pathParams),
      queryParams: Parameters(_normalizeSingleValues(uri.queryParametersAll)),
      fragment: uri.fragment,
    );
  }

  /// Matches a [PageRouteInfo] against the config-entries in [collection]
  ///
  /// The matching here mainly depends on route-name matching
  /// and it does not care about paths
  ///
  /// returns null if not match is found
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
          var match = _matchByRoute(childRoute.copyWith(fragment: route.fragment), subRoutes);
          if (match == null) {
            return null;
          } else {
            childMatches.add(match);
          }
        }
      } else {
        // include default matches if exist
        final defaultMatches = _match(
          Uri(
            path: '',
            queryParameters: _normalizeForUri(route.rawQueryParams),
            fragment: route.fragment,
          ),
          subRoutes,
        );
        if (defaultMatches != null) {
          childMatches.addAll(defaultMatches);
        }
      }
    } else if (route.hasChildren) {
      return null;
    }
    final stringMatch = PageRouteInfo.expandPath(config.path, route.rawPathParams);
    return RouteMatch(
      config: config,
      segments: _split(stringMatch),
      args: route.args,
      key: ValueKey(config.usesPathAsKey ? stringMatch : route.routeName),
      stringMatch: stringMatch,
      fragment: route.fragment,
      redirectedFrom: route.redirectedFrom,
      children: childMatches,
      params: Parameters(route.rawPathParams),
      queryParams: Parameters(route.rawQueryParams),
    );
  }

  /// Builds the track to a certain route in the routes-tree
  ///
  /// This is mainly used to try adding parent routes to the
  /// navigation sequences when pushing child routes without
  /// adding their parents to stack first
  ///
  /// returns null if no track is found
  RouteMatch? buildPathTo(PageRouteInfo<dynamic> route) {
    final configs = collection.findPathTo(route.routeName);
    if (configs.isEmpty) return null;
    final matches = <RouteMatch>[];
    for (var i = 0; i < configs.length; i++) {
      final config = configs[i];
      if (i == configs.length - 1) {
        // last match should take route's info
        final stringMatch = PageRouteInfo.expandPath(config.path, route.rawPathParams);
        matches.add(
          RouteMatch(
            config: config,
            segments: _split(stringMatch),
            args: route.args,
            key: ValueKey(config.usesPathAsKey ? stringMatch : route.routeName),
            stringMatch: stringMatch,
            fragment: route.fragment,
            redirectedFrom: route.redirectedFrom,
            params: Parameters(route.rawPathParams),
            queryParams: Parameters(route.rawQueryParams),
          ),
        );
      } else {
        matches.add(
          RouteMatch(
            config: config,
            segments: _split(config.path),
            key: ValueKey(config.usesPathAsKey ? config.path : config.name),
            stringMatch: config.path,
            autoFilled: true,
          ),
        );
      }
    }
    return UrlState.toHierarchy(matches);
  }

  Map<String, dynamic> _normalizeSingleValues(Map<String, List<String>> queryParametersAll) {
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

  Map<String, dynamic> _normalizeForUri(Map<String, dynamic> queryParameters) {
    final queryMap = <String, dynamic>{};
    for (var key in queryParameters.keys) {
      queryMap[key] = UrlState.normalizeQueryParamValue(queryParameters[key]);
    }
    return queryMap;
  }
}
