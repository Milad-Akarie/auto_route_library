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

  // The url state of each browser entry this history has seen, by serial count.
  // The browser exposes only its current entry, so an earlier entry is known
  // only if it was current while the app navigated away from it.
  final _entries = <int, UrlState>{};

  // The url of the entry this history moved the browser to, until the browser reports it.
  String? _ownMoveUrl;

  bool _isSteppingBack = false;

  @override
  void onNewUrlState(UrlState newState, {bool notify = true}) {
    _recordCurrentEntry();
    // While stepping back, the browser reports the new url once it gets there;
    // a notification now would make the router write it as a new entry.
    super.onNewUrlState(newState, notify: notify && !_isSteppingBack);
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

  // Records the current url state for the current browser entry, if the
  // browser has caught up with it.
  void _recordCurrentEntry() {
    final path = ui_web.urlStrategy?.getPath();
    if (path == null) return;
    if (_isSameUrl(path, urlState.url)) {
      _entries[_currentIndex] = urlState;
    } else {
      _entries.remove(_currentIndex);
    }
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
