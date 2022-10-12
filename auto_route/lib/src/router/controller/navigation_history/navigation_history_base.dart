import 'package:auto_route/src/router/controller/routing_controller.dart';
import 'package:auto_route/src/router/parser/route_information_parser.dart';
import 'package:flutter/widgets.dart';

import 'navigation_history.dart'
    if (dart.library.io) 'native_navigation_history.dart'
    if (dart.library.html) 'web_navigation_history.dart';

abstract class NavigationHistory with ChangeNotifier {
  static NavigationHistory create(StackRouter router) {
    return NavigationHistoryImpl(router);
  }

  void rebuildUrl() {
    final newState = UrlState.fromSegments(
      router.currentSegments,
      shouldReplace: _isUrlStateMarkedForReplace,
    );
    _unMarkUrlStateForReplace();
    onNewUrlState(newState);
  }

  bool _isUrlStateMarkedForReplace = false;

  bool get isUrlStateMarkedForReplace => _isUrlStateMarkedForReplace;

  void markUrlStateForReplace() => _isUrlStateMarkedForReplace = true;

  void _unMarkUrlStateForReplace() => _isUrlStateMarkedForReplace = false;

  UrlState _urlState = UrlState.fromSegments(const []);

  void onNewUrlState(UrlState newState, {bool notify = true}) {
    if (_urlState != newState) {
      _urlState = newState;
      if (notify) {
        notifyListeners();
      }
    }
  }

  bool isRouteActive(String routeName) {
    return urlState.segments.any(
      (r) => r.name == routeName,
    );
  }

  bool isRouteDataActive(RouteData data) {
    return urlState.segments.any(
      (route) => route == data.route,
    );
  }

  bool isPathActive(String pattern) {
    return RegExp(pattern).hasMatch(urlState.path);
  }

  UrlState get urlState => _urlState;

  StackRouter get router;

  bool get canNavigateBack;

  int get length;

  void back();

  void forward();
}
