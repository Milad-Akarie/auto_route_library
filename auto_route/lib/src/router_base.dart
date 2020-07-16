import 'package:auto_route/src/route_data.dart';
import 'package:auto_route/src/route_def.dart';
import 'package:auto_route/src/route_matcher.dart';
import 'package:flutter/widgets.dart';

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
      var name = match.name;
      if (basePath != null) {
        basePath = Uri.parse(basePath).path;
        if (match.name == "" || basePath.endsWith("/") || match.name.startsWith("/")) {
          name = "$basePath${match.name}";
        } else {
          name = "$basePath/${match.name}";
        }
      }
      match = match.copyWith(name: name) as RouteMatch;
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

      print("Pushing: $data");
      var route = pagesMap[match.routeDef.page](data);
      return route;
    }
    return null;
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
        if ((route.template == "/" || route.template.isEmpty) && match.hasRest) {
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
