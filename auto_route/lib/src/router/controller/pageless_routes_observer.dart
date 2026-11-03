import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

/// This ChangeNotifier observes the top-most entry in [Navigator]
/// and reports whether it's a pageless route
///
/// notifies listeners when [hasPagelessTopRoute] is changed
class PagelessRoutesObserver extends NavigatorObserver with ChangeNotifier {
  bool _hasPagelessTopRoute = false;

  // The routes the navigator holds, in no particular order.
  final _routes = <Route<dynamic>>[];

  /// The top-most visible route inside [Navigator]
  Route<dynamic>? current;

  /// Whether the top-most route is a pageless route
  bool get hasPagelessTopRoute => _hasPagelessTopRoute;

  /// The route the [Navigator] shows [page] with, or null while it has not
  /// built one for it yet.
  @internal
  Route<dynamic>? routeOf(Page<dynamic> page) {
    return _routes.lastWhereOrNull((route) => route.settings == page);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // A navigator that was disposed leaves its routes without a navigator.
    _routes
      ..removeWhere((route) => route.navigator == null)
      ..add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _routes.remove(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => _routes.remove(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _routes.remove(oldRoute);
    if (newRoute != null) _routes.add(newRoute);
  }

  @override
  void didChangeTop(Route<dynamic> topRoute, Route<dynamic>? previousTopRoute) {
    current = topRoute;
    final topIsPageless = topRoute.settings is! Page;
    if (_hasPagelessTopRoute != topIsPageless) {
      _hasPagelessTopRoute = topIsPageless;
      notifyListeners();
    }
  }
}
