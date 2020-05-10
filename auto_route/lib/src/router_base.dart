part of 'extended_navigator.dart';

abstract class RouterBase {
  Map<String, List<Type>> get guardedRoutes => null;
  Set<String> get allRoutes => {};
  Route<dynamic> onGenerateRoute(RouteSettings settings);

  /// if initial route is guarded we push
  /// a placeholder route until next distention is
  /// decided by the route guard
  var _initialRouteHasNotBeenRedirected = true;
  Route<dynamic> _onGenerateRoute(
      RouteSettings settings, Object initialRouteArgs) {
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

  Function(RouteSettings settings) _onRePushInitialRoute;

  bool _hasGuards(String routeName) =>
      routeName != null &&
      guardedRoutes != null &&
      guardedRoutes[routeName] != null;
}
