import 'package:flutter/widgets.dart';

/// This ChangeNotifier observes the top-most entry in [Navigator]
/// and reports whether it's a pageless route
///
/// notifies listeners when [hasPagelessTopRoute] is changed
class PagelessRoutesObserver extends NavigatorObserver with ChangeNotifier {
  bool _hasPagelessTopRoute = false;

  /// The top-most visible route inside [Navigator]
  Route<dynamic>? current;

  /// Whether the top-most route is a pageless route
  bool get hasPagelessTopRoute => _hasPagelessTopRoute;

  set hasPagelessTopRoute(bool value) {
    if (value != _hasPagelessTopRoute) {
      _hasPagelessTopRoute = value;
      notifyListeners();
    }
  }

  void _checkCurrentRoute(Route? route) {
    current = route;
    if (route != null) {
      hasPagelessTopRoute = route.settings is! Page;
    }
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    _checkCurrentRoute(route);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _checkCurrentRoute(previousRoute);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    _checkCurrentRoute(previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    _checkCurrentRoute(newRoute);
  }

  @override
  void didStartUserGesture(Route route, Route? previousRoute) {
    _checkCurrentRoute(route);
  }
}
