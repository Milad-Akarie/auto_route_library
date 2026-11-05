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
  final _routes = <Route<Object?>>[];

  // The page route each pageless route was pushed over, directly or over
  // other pageless routes on that page.
  final _pageUnder = <Route<Object?>, Route<Object?>>{};

  /// The top-most visible route inside [Navigator]
  Route<Object?>? current;

  /// Whether the top-most route is a pageless route
  bool get hasPagelessTopRoute => _hasPagelessTopRoute;

  /// The route the [Navigator] shows [page] with, or null while it has not
  /// built one for it yet.
  @internal
  Route<Object?>? routeOf(Page<Object?> page) {
    return _routes.lastWhereOrNull((route) => route.settings == page);
  }

  /// The page route on top of the [Navigator], under the pageless routes
  /// over it, or null before the first route shows.
  @internal
  Route<Object?>? get topPageRoute {
    final top = current;
    return top == null || top.settings is Page ? top : _pageUnder[top];
  }

  /// The last route the [Navigator] holds that passes [test].
  @internal
  Route<Object?>? routeWhere(bool Function(Route<Object?> route) test) {
    return _routes.lastWhereOrNull(
      (route) => route.navigator != null && test(route),
    );
  }

  /// The pageless routes, such as dialogs, the [Navigator] holds over the
  /// route of [pageRoute], below the next page.
  @internal
  List<Route<Object?>> pagelessRoutesOver(Route<Object?> pageRoute) {
    return [
      for (final MapEntry(key: route, value: pageUnder) in _pageUnder.entries)
        if (pageUnder == pageRoute && route.navigator != null) route,
    ];
  }

  @override
  void didPush(Route<Object?> route, Route<Object?>? previousRoute) {
    // A navigator that was disposed leaves its routes without a navigator.
    _routes
      ..removeWhere((each) => each.navigator == null)
      ..add(route);
    _pageUnder.removeWhere((each, _) => each.navigator == null);
    if (route.settings is! Page && previousRoute != null) {
      final pageUnder = previousRoute.settings is Page
          ? previousRoute
          : _pageUnder[previousRoute];
      if (pageUnder != null) _pageUnder[route] = pageUnder;
    }
  }

  @override
  void didPop(Route<Object?> route, Route<Object?>? previousRoute) =>
      _forget(route);

  @override
  void didRemove(Route<Object?> route, Route<Object?>? previousRoute) =>
      _forget(route);

  @override
  void didReplace({Route<Object?>? newRoute, Route<Object?>? oldRoute}) {
    _routes.remove(oldRoute);
    final pageUnder = _pageUnder.remove(oldRoute);
    if (newRoute != null) {
      _routes.add(newRoute);
      if (pageUnder != null && newRoute.settings is! Page) {
        _pageUnder[newRoute] = pageUnder;
      }
    }
  }

  void _forget(Route<Object?> route) {
    _routes.remove(route);
    _pageUnder.remove(route);
  }

  @override
  void didChangeTop(Route<Object?> topRoute, Route<Object?>? previousTopRoute) {
    current = topRoute;
    final topIsPageless = topRoute.settings is! Page;
    if (_hasPagelessTopRoute != topIsPageless) {
      _hasPagelessTopRoute = topIsPageless;
      notifyListeners();
    }
  }
}
