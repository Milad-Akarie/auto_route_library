import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/router/controller/navigation_history/navigation_history_base.dart';
import 'package:web/web.dart';

/// An implementation of [NavigationHistory]
/// That's used for web
class NavigationHistoryImpl extends NavigationHistory {
  /// Default constructor
  NavigationHistoryImpl(this.router);

  @override
  final StackRouter router;

  final History _history = window.history;

  // The url state of each browser entry, by the engine's serial count. The
  // browser exposes only its current entry, so each entry is recorded when the
  // app writes it and checked again whenever the browser shows it.
  final _entries = <int, UrlState>{};

  // The serial count of the entry that holds the app's current url, as far as known.
  int? _appIndex;

  // The url of the entry this history moved the browser to, until the browser reports it.
  String? _ownMoveUrl;

  bool _isSteppingBack = false;

  bool _addsEntryWithSameUrl = false;

  @override
  bool get addsEntryWithSameUrl => _addsEntryWithSameUrl;

  @override
  void onNewUrlState(UrlState newState, {bool notify = true}) {
    final browserIndex = _currentIndex;
    final browserPath = ui_web.urlStrategy?.getPath();
    _recordCurrentEntry();
    final isNewUrl = !_isSameUrl(urlState.url, newState.url);
    // A page pushed over one with the same url gets a browser entry of its own,
    // so that going back returns to the page under it.
    final isPushedOverSameUrl =
        !isNewUrl && !_isSteppingBack && !_isPageOfEntry(browserIndex, newState) && _isPushedOverSameUrl(newState);
    _addsEntryWithSameUrl = notify && isPushedOverSameUrl;
    try {
      // While stepping back, the browser reports the new url once it gets there;
      // a notification now would make the router write it as a new entry.
      super.onNewUrlState(newState, notify: notify && !_isSteppingBack);
    } finally {
      _addsEntryWithSameUrl = false;
    }
    if (_isSteppingBack) return;
    if (!isPushedOverSameUrl && _isSameUrl(browserPath, newState.url) && (isNewUrl || browserIndex != _appIndex)) {
      // The browser moved first, by its own buttons or the address bar; with
      // the same url, to the entry of another page that has it.
      _entries[browserIndex] = newState;
      _appIndex = browserIndex;
    } else if (notify && (isNewUrl || isPushedOverSameUrl)) {
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
    final popped = urlState;
    final newState = UrlState.fromSegments(router.currentSegments);
    final newUrl = newState.url;
    final isSameUrl = newUrl == popped.url;
    _recordCurrentEntry();
    final index = _currentIndex;
    // Whether the entry at index i holds the page on top of [state]; two
    // pages with the same url, pushed one over the other, are told apart by page.
    bool holds(int i, UrlState state) {
      final entry = _entries[i];
      return entry != null &&
          _isSameUrl(entry.url, state.url) &&
          (!isSameUrl || entry.topMatch?.id == state.topMatch?.id);
    }

    if (index > 0 && holds(index, popped) && holds(index - 1, newState)) {
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
    if (isSameUrl) {
      // The popped page wasn't part of the url, or had no entry of its own.
      rebuildUrl();
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
  List<RouteMatch<dynamic>>? routesOfBrowserEntry(UrlState configuration) {
    final entry = _entries[_currentIndex];
    if (entry == null || !entry.hasSegments || !_isSameUrl(entry.url, configuration.url)) return null;
    final pageId = entry.topMatch?.id;
    // The entry's page may still be under the current one with the same url,
    // as when the same route was pushed twice; navigating to it alone would
    // update the current page in place.
    if (pageId != null && _isSameUrl(urlState.url, entry.url)) removePagesAbove(pageId);
    return [UrlState.toHierarchy(entry.segments)];
  }

  @override
  (StackRouter, RouteMatch<dynamic>)? pageToPushForBrowserEntry(UrlState configuration) {
    final appIndex = _appIndex;
    final index = _currentIndex;
    final entry = _entries[index];
    final page = entry?.topMatch;
    final currentPageId = urlState.topMatch?.id;
    if (appIndex == null || index != appIndex + 1 || page == null || currentPageId == null) return null;
    if (!_isSameUrl(entry!.url, configuration.url) || !_isSameUrl(urlState.url, entry.url)) return null;
    if (page.id == currentPageId || controllerOfPage(page.id) != null) return null;
    final holder = controllerOfPage(currentPageId);
    return holder is StackRouter ? (holder, page) : null;
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
  // the browser shows that url and, as far as known, the app's entry: an entry
  // the browser moved to may hold another page with the same url.
  void _recordCurrentEntry() {
    if (!_isSameUrl(ui_web.urlStrategy?.getPath(), urlState.url)) return;
    final index = _currentIndex;
    if (_appIndex != null && _appIndex != index) return;
    _entries[index] = urlState;
    _appIndex = index;
  }

  // Whether the browser entry at [index], which the browser moved to, holds the
  // page on top of [state], as when its forward button reopens a page pushed
  // over one with the same url.
  bool _isPageOfEntry(int index, UrlState state) {
    final pageId = state.topMatch?.id;
    return index != _appIndex && pageId != null && _entries[index]?.topMatch?.id == pageId;
  }

  // Whether [newState] shows a page pushed over the app's current page with the
  // same url, which stays in a stack under it.
  bool _isPushedOverSameUrl(UrlState newState) {
    final currentPageId = urlState.topMatch?.id;
    return currentPageId != null && newState.topMatch?.id != currentPageId && controllerOfPage(currentPageId) != null;
  }

  bool _isSameUrl(String? a, String b) {
    if (a == null) return false;
    // Uri.decodeFull throws on a letter outside ASCII, which a decoded url can
    // hold; parsing first encodes it again.
    String normalize(String url) => url.isEmpty ? '/' : Uri.decodeFull(Uri.parse(url).toString());
    return normalize(a) == normalize(b);
  }

  /// Steps the browser back one entry, unless the app's first entry is current.
  ///
  /// The tab may hold pages from before the app, such as the site the user
  /// came from; stepping back from the app's first entry would leave the app.
  @override
  void back() {
    if (canNavigateBack) _history.back();
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

  /// The number of the app's browser entries up to and including the current one.
  ///
  /// Counts by the engine's serial count, which starts at the app's first entry,
  /// so pages from before the app and entries ahead of the current one are left out.
  @override
  int get length => _currentIndex + 1;

  @override
  void pushPathState(Object? state) {
    onNewUrlState(urlState.copyWith(pathState: state));
  }

  @override
  Object? get pathState => urlState.pathState;
}
