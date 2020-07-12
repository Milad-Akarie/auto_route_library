part of 'extended_navigator.dart';

typedef AutoRouteFactory = Route<dynamic> Function(RouteData data);
typedef RouterBuilder<T extends RouteGenerator> = T Function();

abstract class RouteGenerator {
  List<RouteDef> get routes;

  Map<Type, AutoRouteFactory> get pagesMap;

  Set<String> get allRoutes => routes.map((e) => e.template).toSet();

  Route<dynamic> onGenerateRoute(RouteSettings settings, [String basePath]) {
    assert(routes != null);
    assert(settings != null);
    var match = findMatch(settings);
    if (match != null) {
      var namePrefix = '';
      if (basePath != null) {
        if (settings.name == "" || basePath.endsWith("/") || settings.name.startsWith("/")) {
          namePrefix = basePath;
        } else {
          namePrefix = '$basePath/';
        }
      }

      var matchResult = match.copyWith(name: "$namePrefix${settings.name}") as RouteMatch;

      RouteData data;
      if (matchResult.isParent) {
        data = ParentRouteData(
          matchResult: matchResult,
          initialRoute: matchResult.restAsString,
          routeGenerator: matchResult.routeDef.innerRouter(),
        );
      } else {
        data = RouteData(matchResult);
      }
      var route = pagesMap[matchResult.routeDef.page](data);
      print('pushing: ${data.template}');
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
