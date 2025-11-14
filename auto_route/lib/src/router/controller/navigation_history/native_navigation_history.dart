import 'dart:async';

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

  _HistoryEntry? _lastBackEntry;
  Completer<void>? _backNavigationCompleter;

  @override
  void onNewUrlState(UrlState newState, {bool notify = true}) {
    super.onNewUrlState(newState, notify: notify);
    if (_currentUrl == newState.url) return;
    _addEntry(newState);
  }

  @override
  bool get canNavigateBack => length > 1;

  @override
  int get length => _entries.length;

  String get _currentUrl => _entries.lastOrNull?.url ?? '';

  void _addEntry(UrlState urlState) {
    if (!urlState.hasSegments) return;

    // Skip adding entries during back navigation to prevent duplicate/unwanted entries
    if (_backNavigationCompleter != null && !_backNavigationCompleter!.isCompleted) {
      // If this is the target URL from back navigation, complete the navigation
      if (_lastBackEntry?.url == urlState.url) {
        _backNavigationCompleter!.complete();
        _backNavigationCompleter = null;
      }
      return;
    }

    final route = UrlState.toHierarchy(urlState.segments);
    final newEntry = _HistoryEntry(route, urlState.url);

    // Check if we're adding the same entry as the last one (prevent duplicates)
    if (_entries.isNotEmpty && _entries.last.url == urlState.url) {
      return;
    }

    if (_lastBackEntry?.url != urlState.url) {
      _lastBackEntry = null;
    }

    // limit history registration to 20 entries
    if (_entries.length > 20) {
      _entries.removeAt(0);
    }
    if (urlState.shouldReplace && length > 0) {
      _entries.removeLast();
    }
    _entries.add(newEntry);
  }

  @override
  void back() {
    if (canNavigateBack) {
      _backNavigationCompleter = Completer<void>();
      _entries.removeLast();

      if (_lastBackEntry != null) {
        if (_entries.isNotEmpty && _entries.last.url == _lastBackEntry!.url) {
          _entries.removeLast();
        }
      }

      if (_entries.isEmpty) {
        _backNavigationCompleter = null;
        return;
      }

      var lastEntry = _entries.last;
      _lastBackEntry = lastEntry;

      // Navigate and complete the navigation when done
      unawaited(router.navigateAll([lastEntry.route]).then((_) {
        _backNavigationCompleter?.complete();
        _backNavigationCompleter = null;
      }));
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
