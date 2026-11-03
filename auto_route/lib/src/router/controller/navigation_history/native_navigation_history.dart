import 'package:auto_route/auto_route.dart' show RouteMatch, StackRouter, UrlState;
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import 'navigation_history_base.dart';

/// An implementation of [NavigationHistory]
/// That's used for native platforms
class NavigationHistoryImpl extends NavigationHistory {
  /// Default constructor;
  NavigationHistoryImpl(this.router);

  @override
  final StackRouter router;

  final _entries = <_HistoryEntry>[];
  bool _isNavigatingBack = false;
  bool _isRebuildingAfterPop = false;

  @override
  void onNewUrlState(UrlState newState, {bool notify = true}) {
    super.onNewUrlState(newState, notify: notify);
    if (_currentUrl == newState.url) return;

    // Don't add entries during back navigation to prevent duplicates
    if (_isNavigatingBack) return;

    if (_isRebuildingAfterPop) {
      // The last entry belongs to the popped page; drop it so back() can't return to it.
      // If the page now on top is the entry before, _addEntry skips it as a duplicate.
      if (_entries.isNotEmpty) _entries.removeLast();
      _addEntry(newState.copyWith(shouldReplace: false));
      return;
    }

    _addEntry(newState);
  }

  @override
  void rebuildUrlAfterPop() {
    _isRebuildingAfterPop = true;
    try {
      rebuildUrl();
    } finally {
      _isRebuildingAfterPop = false;
    }
  }

  @override
  bool get canNavigateBack => length > 1 && !_isNavigatingBack;

  @override
  int get length => _entries.length;

  String get _currentUrl => _entries.lastOrNull?.url ?? '';

  void _addEntry(UrlState urlState) {
    if (!urlState.hasSegments) return;
    final route = UrlState.toHierarchy(urlState.segments);
    final newEntry = _HistoryEntry(route, urlState.url);

    // Prevent adding duplicate consecutive entries
    if (_entries.isNotEmpty && _entries.last.url == urlState.url) {
      return;
    }

    // limit history registration to 20 entries
    if (_entries.length > 20) {
      _entries.removeAt(0);
    }
    if (urlState.shouldReplace && length > 0) {
      _entries.removeLast();
      // The entry before may already hold this url, e.g. the page a redirect was shown for.
      if (_entries.lastOrNull?.url == urlState.url) return;
    }
    _entries.add(newEntry);
  }

  @override
  void back() {
    if (canNavigateBack) {
      _isNavigatingBack = true;
      _entries.removeLast();

      if (_entries.isEmpty) {
        _isNavigatingBack = false;
        return;
      }

      router.navigateAll([_entries.last.route]).whenComplete(() => _isNavigatingBack = false);
    }
  }

  @override
  void forward() {
    throw FlutterError('forward navigation is not supported for non-web platforms');
  }

  @override
  Object? get pathState => throw FlutterError('pathState is not supported for non-web platforms');

  @override
  void pushPathState(Object? state) {
    throw FlutterError('pushPathState is not supported for non-web platforms');
  }
}

class _HistoryEntry {
  final RouteMatch route;
  final String url;

  const _HistoryEntry(this.route, this.url);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is _HistoryEntry && runtimeType == other.runtimeType && url == other.url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() {
    return route.flattened.map((e) => e.name).join('->');
  }
}
