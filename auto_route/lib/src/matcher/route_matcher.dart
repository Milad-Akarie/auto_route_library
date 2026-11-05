import 'package:auto_route/auto_route.dart';
import 'package:cupertino_ui/cupertino_ui.dart';

/// Matches paths and [PageRouteInfo]s with
/// the given [collection]
class RouteMatcher {
  /// Default constructor
  const RouteMatcher(this.collection);

  /// The list of route-entries to match against
  final RouteCollection collection;

  /// Parses a [Uri] from [rawPath] then maps call to [_match]
  List<RouteMatch<Object?>>? match(String rawPath, {bool includePrefixMatches = false}) {
    return _match(Uri.parse(rawPath), collection, includePrefixMatches: includePrefixMatches, root: true);
  }

  /// Matches a uri against the config-entries in [collection]
  ///
  /// if [includePrefixMatches] is true prefixed matches
  /// will be included in the return list
  ///
  /// returns null if not match is found
  List<RouteMatch<Object?>>? matchUri(Uri uri, {bool includePrefixMatches = false}) {
    return _match(uri, collection, includePrefixMatches: includePrefixMatches, root: true);
  }

  List<RouteMatch<Object?>>? _match(
    Uri uri,
    RouteCollection routeCollection, {
    bool includePrefixMatches = false,
    bool root = false,
    String? redirectedFrom,
    List<String> redirectChain = const [],
  }) {
    final pathSegments = _split(uri.path);
    final matches = <RouteMatch<Object?>>[];
    for (final config in routeCollection.routes) {
      var match = _matchByPath(uri, pathSegments, config, redirectedFrom: redirectedFrom);
      if (match != null) {
        if (!includePrefixMatches || config.path == '*') {
          matches.clear();
        }
        // handle redirects
        if (config is RedirectRoute) {
          final redirectToUri = Uri.parse(PageRouteInfo.expandPath(config.redirectTo, match.params.rawMap));
          final redirectFrom = PageRouteInfo.expandPath(config.path, match.params.rawMap);
          if (redirectChain.contains(redirectFrom)) {
            throw FlutterError(
              'Redirect loop detected: ${[...redirectChain, redirectFrom].join(' -> ')}\n'
              'The RedirectRoutes above send the url back to one that was already redirected. '
              'Change the redirectTo of one of them so the chain ends at a page.',
            );
          }
          return _handleRedirect(
            redirectChain: [...redirectChain, redirectFrom],
            routesCollection: routeCollection,
            includePrefixMatches: includePrefixMatches,
            redirectTo: redirectToUri.replace(
              queryParameters: {...redirectToUri.queryParametersAll, ...uri.queryParametersAll},
              fragment: uri.fragment,
            ),
            redirectedFrom: PageRouteInfo.expandPath(config.path, match.params.rawMap),
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
              routeCollection.subCollectionOf(config.name),
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
            match = match.copyWith(
              children: _match(uri.replace(path: ''), routeCollection.subCollectionOf(config.name)),
            );
          }

          matches.add(match);
          break;
        }
      }
    }

    if (matches.isEmpty || (root && _consumedSegments(matches.last) < pathSegments.length)) {
      return null;
    }
    return matches;
  }

  List<RouteMatch<Object?>>? _handleRedirect({
    required RouteCollection routesCollection,
    required bool includePrefixMatches,
    required Uri redirectTo,
    required String redirectedFrom,
    required List<String> redirectChain,
  }) {
    return _match(
      redirectChain: redirectChain,
      redirectTo,
      routesCollection,
      includePrefixMatches: includePrefixMatches,
      redirectedFrom: redirectedFrom,
    );
  }

  // How many segments of the url [match] and its children consumed. A match
  // with no segments of its own consumed none, unless a redirect to an empty
  // path made it: then it stands for the segment the redirect matched. So a
  // path no route has doesn't match the '' route of a router.
  static int _consumedSegments(RouteMatch<Object?> match) {
    final own = match.segments.isEmpty && match.redirectedFrom != null ? 1 : match.segments.length;
    return own + (match.hasChildren ? _consumedSegments(match.children!.last) : 0);
  }

  // Splits a url's path at each '/': the root '/' first when the path has one,
  // then each segment that isn't empty. Escapes stay as they are, so an
  // encoded '/' stays inside its segment. A url's separator is '/' on every
  // platform, so this doesn't split at a backslash on Windows.
  static List<String> _split(String path) {
    final segments = <String>[if (path.startsWith('/')) '/'];
    for (final segment in path.split('/')) {
      if (segment.isNotEmpty) segments.add(segment);
    }
    return segments;
  }

  // Joins segments split by [_split] back into a path.
  static String _join(List<String> segments) {
    if (segments.isNotEmpty && segments.first == '/') return '/${segments.skip(1).join('/')}';
    return segments.join('/');
  }

  // The segments of each route's path. A route's path never changes, and
  // matching a url compares it with every route until one matches, so each
  // path is split once instead of on every match.
  static final _pathParts = Expando<List<String>>('path parts');

  List<String> _partsOf(AutoRoute config) => _pathParts[config] ??= _split(config.path);

  /// Matches a uri against a route-config [AutoRoute]
  /// and returns a single match result
  ///
  /// returns null if not match is found
  RouteMatch<Object?>? matchByPath(Uri uri, AutoRoute config, {String? redirectedFrom}) {
    // Split before decoding, so an encoded '/' stays inside its segment.
    return _matchByPath(uri, _split(uri.path), config, redirectedFrom: redirectedFrom);
  }

  // [segments] is the path of [uri], split.
  RouteMatch<Object?>? _matchByPath(Uri uri, List<String> segments, AutoRoute config, {String? redirectedFrom}) {
    final parts = _partsOf(config);

    if (parts.length > segments.length) {
      return null;
    }

    if (config.fullMatch && segments.length > parts.length && (parts.isEmpty || parts.last != '*')) {
      return null;
    }

    final pathParams = <String, String>{};
    for (var index = 0; index < parts.length; index++) {
      final segment = segments[index];
      final part = parts[index];
      if (part.startsWith(':')) {
        pathParams[part.substring(1)] = Uri.decodeComponent(segment);
      } else if (Uri.decodeComponent(segment) != part && part != '*') {
        return null;
      }
    }

    var extractedSegments = segments.sublist(0, parts.length);
    if (parts.isNotEmpty && parts.last == '*') {
      // A copy: [segments] is shared by every route this url is matched against.
      extractedSegments = List.of(segments);
    }

    final stringMatch = _join(extractedSegments);
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
  RouteMatch<Object?>? matchByRoute(PageRouteInfo route) {
    return _matchByRoute(route, collection);
  }

  RouteMatch<Object?>? _matchByRoute(PageRouteInfo route, RouteCollection routes) {
    final config = routes[route.routeName];
    if (config == null) {
      return null;
    }
    final childMatches = <RouteMatch<Object?>>[];
    if (config.hasSubTree) {
      final subRoutes = routes.subCollectionOf(route.routeName);
      if (route.hasChildren) {
        for (final childRoute in route.initialChildren!) {
          final match = _matchByRoute(childRoute.copyWith(fragment: route.fragment), subRoutes);
          if (match == null) {
            return null;
          }
          childMatches.add(match);
        }
      } else {
        // include default matches if exist
        final defaultMatches = _match(
          Uri(path: '', queryParameters: _normalizeForUri(route.rawQueryParams), fragment: route.fragment),
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
  RouteMatch<Object?>? buildPathTo(PageRouteInfo<Object?> route) {
    final configs = collection.findPathTo(route.routeName);
    if (configs.isEmpty) return null;
    final matches = <RouteMatch<Object?>>[];
    for (var i = 0; i < configs.length; i++) {
      final config = configs[i];
      if (i == configs.length - 1) {
        // last match should take route's info, and the default children it
        // gets when matched by route from its own level, which carry its query
        var routes = collection;
        for (final ancestor in configs.take(i)) {
          routes = routes.subCollectionOf(ancestor.name);
        }
        final children = _matchByRoute(route, routes)?.children;
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
            children: children == null || children.isEmpty ? null : children,
          ),
        );
      } else {
        // A path param of the route can belong to an ancestor's path, as with a
        // page at '' under 'books/:id'; fill it in there too.
        final ancestorParams = {
          for (final entry in route.rawPathParams.entries)
            if (_split(config.path).contains(':${entry.key}')) entry.key: entry.value,
        };
        final stringMatch = PageRouteInfo.expandPath(config.path, ancestorParams);
        matches.add(
          RouteMatch(
            config: config,
            segments: _split(stringMatch),
            key: ValueKey(config.usesPathAsKey ? stringMatch : config.name),
            stringMatch: stringMatch,
            params: Parameters(ancestorParams),
            autoFilled: true,
          ),
        );
      }
    }
    return UrlState.toHierarchy(matches);
  }

  Map<String, Object?> _normalizeSingleValues(Map<String, List<String>> queryParametersAll) {
    final queryMap = <String, Object?>{};
    for (final key in queryParametersAll.keys) {
      final list = queryParametersAll[key];
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

  Map<String, Object?> _normalizeForUri(Map<String, Object?> queryParameters) {
    final queryMap = <String, Object?>{};
    for (final key in queryParameters.keys) {
      queryMap[key] = UrlState.normalizeQueryParamValue(queryParameters[key]);
    }
    return queryMap;
  }
}
