part of 'extended_navigator.dart';

typedef AutoRouteFactory = Route<dynamic> Function(RouteData data);
typedef RouterBuilder<T extends RouterBase> = T Function();

abstract class RouterBase {
  Map<String, List<Type>> get guardedRoutes => null;

  Set<String> get allRoutes => routesMap.keys.toSet();

  Map<String, RouterBuilder> get subRouters => {};

  Map<String, AutoRouteFactory> routesMap = {};

  Route<dynamic> onGenerateRoute(RouteSettings settings, [String basePath]) {
    assert(settings != null);
    assert(routesMap != null);

    var matchResult = findFullMatch(settings);
    matchResult.copyWith(name: "${basePath ??= ''}${settings.name}");
    if (matchResult != null) {
      RouteData data;
      if (hasNestedRouter(matchResult.template)) {
        data = ParentRouteData(
          matchResult: matchResult,
          initialRoute: matchResult.rest.toString(),
          router: subRouters[matchResult.template](),
        );
      } else {
        data = RouteData(matchResult);
      }
      print('pushing: $data');
      return routesMap[matchResult.template](data);
    }
    return null;
  }

  bool hasNestedRouter(String template) => subRouters != null && subRouters[template] != null;

  Route<dynamic> onRouteNotFound(RouteSettings settings) {
    return defaultUnknownRoutePage(settings?.name);
  }

  // a shorthand for calling the onGenerateRoute function
  // when using Router directly in MaterialApp or such
  // Router().onGenerateRoute becomes Router()
  Route<dynamic> call(RouteSettings settings) => onGenerateRoute(settings);

  MatchResult findFullMatch(RouteSettings settings) {
    // deep links are  pre-matched
    if (settings is MatchResult) {
      return settings;
    }
    final matcher = RouteMatcher(settings);
    for (var route in allRoutes) {
      var match = matcher.match(route, fullMatch: true);
      if (match != null) {
        return match;
      }
    }
    return null;
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
