import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:auto_route/auto_route.dart';
import 'package:web/web.dart';

import 'navigation_history_base.dart';

/// An implementation of [NavigationHistory]
/// That's used for web
class NavigationHistoryImpl extends NavigationHistory {
  /// Default constructor
  NavigationHistoryImpl(this.router);

  @override
  final StackRouter router;

  final _history = window.history;

  // The url state of each browser entry, by the engine's serial count. The
  // browser exposes only its current entry, so each entry is recorded when the
  // app writes it and checked again whenever the browser shows it.
  final _entries = <int, UrlState>{};

  // The serial count of the entry that holds the app's current url, as far as known.
  int? _appIndex;

  // The url of the entry this history moved the browser to, until the browser reports it.
  String? _ownMoveUrl;

  bool _isSteppingBack = false;

  @override
  void onNewUrlState(UrlState newState, {bool notify = true}) {
    final browserIndex = _currentIndex;
    final browserPath = ui_web.urlStrategy?.getPath();
    _recordCurrentEntry();
    final isNewUrl = !_isSameUrl(urlState.url, newState.url);
    // While stepping back, the browser reports the new url once it gets there;
    // a notification now would make the router write it as a new entry.
    super.onNewUrlState(newState, notify: notify && !_isSteppingBack);
    if (!isNewUrl || _isSteppingBack) return;
    if (_isSameUrl(browserPath, newState.url)) {
      // The browser moved first, by its own buttons or the address bar.
      _entries[browserIndex] = newState;
      _appIndex = browserIndex;
    } else if (notify) {
      // The router writes the new url after this frame: over the current entry
      // for a replace, otherwise as a new entry, which drops those after it.
      final index = (_appIndex ?? browserIndex) + (newState.shouldReplace ? 0 : 1);
      _entries.removeWhere((key, _) => key >= index);
      _entries[index] = newState;
      _appIndex = index;
    }
  }

  @override
  void rebuildUrlAfterPop() {
    final poppedUrl = urlState.url;
    final newUrl = UrlState.fromSegments(router.currentSegments).url;
    if (newUrl == poppedUrl) {
      rebuildUrl();
      return;
    }
    _recordCurrentEntry();
    final index = _currentIndex;
    final isPoppedPageCurrent = _isSameUrl(_entries[index]?.url, poppedUrl);
    if (index > 0 && isPoppedPageCurrent && _isSameUrl(_entries[index - 1]?.url, newUrl)) {
      _isSteppingBack = true;
      try {
        rebuildUrl();
      } finally {
        _isSteppingBack = false;
      }
      _appIndex = index - 1;
      _ownMoveUrl = newUrl;
      _history.back();
      return;
    }
    // The entry before belongs to another page, so the page now on top takes
    // the popped page's entry.
    markUrlStateForReplace();
    rebuildUrl();
  }

  @override
  bool consumeOwnBrowserMove(UrlState configuration) {
    final ownMoveUrl = _ownMoveUrl;
    _ownMoveUrl = null;
    return ownMoveUrl != null && _isSameUrl(configuration.url, ownMoveUrl);
  }

  @override
  List<RouteMatch>? routesOfBrowserEntry(UrlState configuration) {
    final entry = _entries[_currentIndex];
    if (entry == null || !entry.hasSegments || !_isSameUrl(entry.url, configuration.url)) return null;
    return [UrlState.toHierarchy(entry.segments)];
  }

  @override
  bool get isBrowserBehindApp {
    final appIndex = _appIndex;
    return appIndex != null && _currentIndex < appIndex;
  }

  @override
  void returnBrowserToApp() {
    final appIndex = _appIndex;
    if (appIndex == null || _currentIndex >= appIndex) return;
    _ownMoveUrl = urlState.url;
    _history.go(appIndex - _currentIndex);
  }

  // Records the app's current url state for the current browser entry, if
  // the browser shows that url.
  void _recordCurrentEntry() {
    if (!_isSameUrl(ui_web.urlStrategy?.getPath(), urlState.url)) return;
    final index = _currentIndex;
    _entries[index] = urlState;
    _appIndex = index;
  }

  bool _isSameUrl(String? a, String b) {
    if (a == null) return false;
    String normalize(String url) => url.isEmpty ? '/' : Uri.decodeFull(url);
    return normalize(a) == normalize(b);
  }

  @override
  void back() {
    _history.back();
  }

  int get _currentIndex {
    final state = _history.state.dartify();
    if (state is Map) {
      final serialCount = state['serialCount'];
      if (serialCount is num) {
        return serialCount.toInt();
      }
    }
    return 0;
  }

  @override
  bool get canNavigateBack => _currentIndex > 0;

  @override
  void forward() => _history.forward();

  @override
  int get length => _history.length;

  @override
  void pushPathState(Object? state) {
    onNewUrlState(urlState.copyWith(pathState: state));
  }

  @override
  Object? get pathState => urlState.pathState;
}
