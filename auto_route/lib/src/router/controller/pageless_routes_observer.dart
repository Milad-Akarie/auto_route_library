import 'package:flutter/widgets.dart';

class PagelessRoutesObserver extends NavigatorObserver with ChangeNotifier {
  bool _hasPagelessTopRoute = false;
  Route<dynamic>? current;

  bool get hasPagelessTopRoute => _hasPagelessTopRoute;

  set hasPagelessTopRoute(value) {
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
}
