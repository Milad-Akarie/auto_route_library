import 'package:auto_route/src/matcher/route_match.dart';
import 'package:auto_route/src/router/controller/routing_controller.dart';
import 'package:auto_route/src/router/parser/route_information_parser.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

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

  /// Rebuilds the url after a page was popped from one of [router]'s stacks.
  ///
  /// A pop leaves the page that was under the popped one on top. Recording
  /// that page as a new entry, as [rebuildUrl] would, leaves the popped page's
  /// entry in the history, so a later [back] returns to the page that was just
  /// popped. The native history instead drops the popped page's entry and
  /// keeps one entry for the page now on top. The web history cannot delete
  /// browser entries: when the entry before holds the page now on top, it steps
  /// the browser back to it (see [consumeOwnBrowserMove]); otherwise it gives
  /// the popped page's entry to the page now on top.
  ///
  /// Like [rebuildUrl], notifies listeners only if the url changed, which it
  /// does not when the popped page was not part of the visible url.
  @internal
  void rebuildUrlAfterPop() => rebuildUrl();

  /// Whether [configuration], a route the platform just reported, only
  /// confirms a move through the browser history that this history made itself.
  ///
  /// The web history sometimes moves the browser on its own, for example to
  /// step back over a page that was popped in the app. The browser then reports
  /// the entry it lands on like any navigation by the user, although the app
  /// already shows that route. [AutoRouterDelegate.setNewRoutePath] skips such a
  /// report instead of handling it as a deep link, which would close dialogs,
  /// rerun the deep link builder and rebuild the stack.
  ///
  /// Each call consumes the expected move, matched or not: only the first
  /// report after the move can match, and a report for a different url returns
  /// false and is handled as usual. Always false on native platforms, where the
  /// history never moves on its own.
  @internal
  bool consumeOwnBrowserMove(UrlState configuration) => false;

  /// The routes the app showed when it wrote the browser entry that
  /// [configuration], a route the platform just reported, came from.
  ///
  /// A browser entry holds only a url, so a page reopened from it by the
  /// browser's back or forward button would lose the arguments the url can't
  /// carry. The web history remembers the routes of each entry it wrote, with
  /// their arguments, and [AutoRouterDelegate.setNewRoutePath] navigates to
  /// those instead of the routes parsed from the url.
  ///
  /// Returns a single route holding its children, as [UrlState.toHierarchy]
  /// builds it, or null when the current entry wasn't written by this history
  /// or now holds a different url, such as one typed into the address bar.
  /// Always null on native platforms.
  @internal
  List<RouteMatch>? routesOfBrowserEntry(UrlState configuration) => null;

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
