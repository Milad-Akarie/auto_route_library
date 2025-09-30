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
    final route = UrlState.toHierarchy(urlState.segments);
    // limit history registration to 20 entries
    if (_entries.length > 20) {
      _entries.removeAt(0);
    }
    if (urlState.shouldReplace && length > 0) {
      _entries.removeLast();
    }
    _entries.add(_HistoryEntry(route, urlState.url));
  }

  @override
  void back() {
    if (canNavigateBack) {
      _entries.removeLast();
      router.navigateAll([_entries.last.route]);
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
