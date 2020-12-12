import 'package:flutter/widgets.dart';

import 'route_data.dart';
import 'route_def.dart';
import 'route_matcher.dart';

typedef AutoRouteFactory = Route<dynamic> Function(RouteData data);
typedef RouterBuilder<T extends RouterBase> = T Function();

abstract class RouterBase {
  List<RouteDef> get routes;

  Map<Type, AutoRouteFactory> get pagesMap;

  Set<String> get allRoutes => routes.map((e) => e.template).toSet();

  Route<dynamic> onGenerateRoute(RouteSettings settings, [String basePath]) {
    assert(routes != null);
    assert(settings != null);
    var match = findMatch(settings);
    if (match != null) {
      if (basePath != null) {
        match = match.replace(name: _joinPath(basePath, match.name));
      }

      RouteData data;
      if (match.isParent) {
        data = ParentRouteData(
          matchResult: match,
          initialRoute: match.rest,
          router: match.routeDef.generator,
        );
      } else {
        data = RouteData(match);
      }
      return pagesMap[match.routeDef.page](data);
    }
    return null;
  }

  String _joinPath(String basePath, String part) {
    var name;
    var path = Uri.parse(basePath).path;
    if (part == "" || path.endsWith("/") || part.startsWith("/")) {
      name = "$path$part";
    } else {
      name = "$path/$part";
    }
    return name;
  }

  // a shorthand for calling the onGenerateRoute function
  // when using Router directly in MaterialApp or such
  // Router().onGenerateRoute becomes Router()
  Route<dynamic> call(RouteSettings settings) => onGenerateRoute(settings);

  RouteMatch findMatch(RouteSettings settings) {
    var matcher = RouteMatcher(settings);
    for (var route in routes) {
      var match = matcher.match(route);
      if (match != null) {
        // matching root "/" must be exact
        if ((route.template == "/" || route.template.isEmpty) &&
            match.hasRest) {
          continue;
        }
        return match;
      }
    }
    return null;
  }

  bool hasMatch(String path) {
    return findMatch(RouteSettings(name: path)) != null;
  }

  List<RouteMatch> allMatches(RouteMatcher matcher) {
    var matches = <RouteMatch>[];
    for (var route in routes) {
      var matchResult = matcher.match(route);
      if (matchResult != null) {
        matches.add(matchResult);
        if (matchResult.isParent || !matchResult.hasRest) {
          break;
        }
      }
    }
    return matches;
  }
}
