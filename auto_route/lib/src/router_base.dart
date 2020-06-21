part of 'extended_navigator.dart';

typedef AutoRouteFactory = Route<dynamic> Function(RouteData data);
typedef RouterBuilder<T extends RouterBase> = T Function();

abstract class RouterBase {
  Map<String, List<Type>> get guardedRoutes => null;
  Map<String, RouterBuilder> get subRouters => {};
  Map<String, AutoRouteFactory> routesMap = {};

  Set<String> get allRoutes => routesMap.keys.toSet();

  Route<dynamic> onGenerateRoute(RouteSettings settings, [String basePath]) {
    assert(routesMap != null);
    assert(settings != null);

    var match = findFullMatch(settings);
    if (match != null) {
      var matchResult = match.copyWith(name: "${basePath ??= ''}${settings.name}") as MatchResult;
      RouteData data;
      if (isParentRoute(matchResult.template)) {
        data = _ParentRouteData(
          matchResult: matchResult,
          initialRoute: matchResult.rest.toString(),
          router: subRouters[matchResult.template](),
        );
      } else {
        data = RouteData(matchResult);
      }
      return routesMap[matchResult.template](data);
    }
    return null;
  }

  bool isParentRoute(String template) => subRouters != null && subRouters[template] != null;


  // a shorthand for calling the onGenerateRoute function
  // when using Router directly in MaterialApp or such
  // Router().onGenerateRoute becomes Router()
  Route<dynamic> call(RouteSettings settings) => onGenerateRoute(settings);

  MatchResult findFullMatch(RouteSettings settings) {
    // deep links are  pre-matched
    MatchResult matchResult;
    if (settings is MatchResult) {
      matchResult = settings;
    } else {
      final matcher = RouteMatcher(settings);
      for (var route in allRoutes) {
        var match = matcher.match(route, fullMatch: true);
        if (match != null) {
          matchResult = match;
          break;
        }
      }
    }
     return matchResult;
  }

  List<MatchResult> allMatches(RouteMatcher matcher) {
    var matches = <MatchResult>[];
    for (var template in allRoutes) {
      var matchResult = matcher.match(template);
      if (matchResult != null) {
        matches.add(matchResult);
        if (isParentRoute(template) || !matchResult.hasRest) {
          break;
        }
      }
    }
    return matches;
  }

  MatchResult match(RouteSettings settings) {
    final matcher = RouteMatcher(settings);
    for (var route in allRoutes) {
      var match = matcher.match(route);
      if (match != null) {
        return match;
      }
    }
    return null;
  }

  bool _hasGuards(String routeName) => routeName != null && guardedRoutes != null && guardedRoutes[routeName] != null;
}
