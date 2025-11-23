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
