part of 'extended_navigator.dart';

abstract class RouterBase {
  Map<String, List<Type>> get guardedRoutes => null;

  Set<String> get allRoutes => {};

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final match = findFullMatch(settings);
    if (match != null) {
      return routesMap[match](settings);
    }
    return onRouteNotFound(settings);
  }

  Route<dynamic> onRouteNotFound(RouteSettings settings) {
    return unknownRoutePage(settings.name);
  }

  Map<String, RouteFactory> routesMap;

  // a shorthand for calling the onGenerateRoute function
  // when using Router directly in MaterialApp or such
  // Router().onGenerateRoute becomes Router()
  Route<dynamic> call(RouteSettings settings) => onGenerateRoute(settings);

  /// if initial route is guarded we push
  /// a placeholder route until next distention is
  /// decided by the route guard
  var _initialRouteHasNotBeenRedirected = true;

  Route<dynamic> _onGenerateRoute(RouteSettings settings, Object initialRouteArgs) {
    final routeName = settings.name;
    if (routeName == '/') {
      settings = settings.copyWith(arguments: initialRouteArgs);
      if (_hasGuards(routeName) && _initialRouteHasNotBeenRedirected) {
        _initialRouteHasNotBeenRedirected = false;
        assert(_onRePushInitialRoute != null);
        _onRePushInitialRoute(settings);
        return PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 0),
          pageBuilder: (_, __, ___) => Container(
            color: Colors.white,
          ),
        );
      }
    }

    return onGenerateRoute(settings);
  }

// returns route match or null
//  List<UriMatch> findMatches(Uri uri) {
//    var matches =
//    if (uri == null) {
//      return null;
//    }
//    for (var route in allRoutes) {
//      print(route);
//      var match = UriParser(UriTemplate(route)).match(uri);
//      if (match != null) {
//        return match;
//      }
//    }
//    return null;
//  }

  String findFullMatch(RouteSettings settings) {
    var uri = Uri.tryParse(settings.name);
    if (uri == null) {
      return null;
    }
    final matcher = RouteMatcher(uri);
    for (var route in allRoutes) {
      if (matcher.hasFullMatch(route)) {
        return route;
      }
    }
    return null;
  }

  Function(RouteSettings settings) _onRePushInitialRoute;

  bool _hasGuards(String routeName) => routeName != null && guardedRoutes != null && guardedRoutes[routeName] != null;
}
