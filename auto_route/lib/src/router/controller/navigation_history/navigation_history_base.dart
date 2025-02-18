import 'package:auto_route/src/router/controller/routing_controller.dart';
import 'package:auto_route/src/router/parser/route_information_parser.dart';
import 'package:flutter/widgets.dart';

import 'navigation_history.dart'
    if (dart.library.io) 'native_navigation_history.dart'
    if (dart.library.js_interop) 'web_navigation_history.dart';

/// An abstraction on a navigation history tracker
/// that utilises browser history on web and mimics it on native
abstract class NavigationHistory with ChangeNotifier {
  /// Creates an instance of [NavigationHistoryImpl]
  static NavigationHistory create(StackRouter router) {
    return NavigationHistoryImpl(router);
  }

  /// Forces url to rebuild if generated state
  /// is different from current
  void rebuildUrl() {
    final newState = UrlState.fromSegments(
      router.currentSegments,
      shouldReplace: _isUrlStateMarkedForReplace,
    );
    _unMarkUrlStateForReplace();
    onNewUrlState(newState);
  }

  /// Pushes a new browser entry with given state
  ///
  /// only works for web
  void pushPathState(Object? state);

  /// Reads the current browser entry state
  ///
  /// only works for web
  Object? get pathState;

  bool _isUrlStateMarkedForReplace = false;

  /// Whether next browser entry update should replace current
  bool get isUrlStateMarkedForReplace => _isUrlStateMarkedForReplace;

  /// Force next browser entry update to replace current
  void markUrlStateForReplace() => _isUrlStateMarkedForReplace = true;

  void _unMarkUrlStateForReplace() => _isUrlStateMarkedForReplace = false;

  UrlState _urlState = UrlState.fromSegments(const []);

  /// Notifies [AutoRouteDelegate] of url configuration changed
  /// if [newState] is different from current
  void onNewUrlState(UrlState newState, {bool notify = true}) {
    if (_urlState != newState) {
      _urlState = newState;
      if (notify) {
        notifyListeners();
      }
    }
  }

  /// Whether this route is in the visible urlState-segments
  bool isRouteActive(String routeName) {
    return urlState.segments.any(
      (r) => r.name == routeName,
    );
  }

  /// Whether this route-data is in the visible urlState-segments
  bool isRouteDataActive(RouteData data) {
    return urlState.segments.any(
      (route) => route == data.route,
    );
  }

  /// Whether this path-pattern is in the visible urlState-segments
  bool isPathActive(String pattern) {
    return RegExp(pattern).hasMatch(urlState.path);
  }

  /// Helper to access current [_urlState]
  UrlState get urlState => _urlState;

  /// The root router
  StackRouter get router;

  /// Whether managed history has more than one entry
  bool get canNavigateBack;

  /// The length of managed history entries
  int get length;

  /// Navigate back one entry in history
  ///
  /// does nothing if history has only one entry
  void back();

  /// Navigate forward one entry in history
  ///
  /// only works for web
  void forward();
}
