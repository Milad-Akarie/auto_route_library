import 'package:auto_route/auto_route.dart' show RouteMatch, RoutingController, StackRouter, UrlState;
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
    if (_isLastEntry(newState)) return;

    // Don't add entries during back navigation to prevent duplicates
    if (_isNavigatingBack) return;

    if (_isRebuildingAfterPop) {
      // The last entry belongs to the popped page; drop it so back() can't return to it.
      // If the page now on top is the entry before, _addEntry skips it as the same page.
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

  // Whether [urlState] shows the page of the last entry.
  bool _isLastEntry(UrlState urlState) {
    final last = _entries.lastOrNull;
    return last != null && last.url == urlState.url && last.pageId == urlState.topMatch?.id;
  }

  // The controller, [controller] or one nested in it, whose stack holds the page with [pageId].
  RoutingController? _controllerOf(RoutingController controller, LocalKey pageId) {
    if (controller.stackData.any((data) => data.route.id == pageId)) return controller;
    for (final child in controller.childControllers) {
      final holder = _controllerOf(child, pageId);
      if (holder != null) return holder;
    }
    return null;
  }

  void _addEntry(UrlState urlState) {
    if (!urlState.hasSegments) return;
    final route = UrlState.toHierarchy(urlState.segments);
    final newEntry = _HistoryEntry(route, urlState.url, urlState.topMatch!.id);

    if (_isLastEntry(urlState)) return;
    // A page with the same url as the last entry's is a new entry only while the
    // last entry's page stays in a stack under it, as when the same route is
    // pushed twice. Otherwise it took that page's place, as navigate() does with
    // new arguments, or the router rebuilt its pages, so it takes the entry.
    final last = _entries.lastOrNull;
    if (last != null && last.url == urlState.url && _controllerOf(router, last.pageId) == null) {
      _entries.removeLast();
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

      // The entry's page may still be under the current one with the same route
      // name, which navigateAll alone would update in place; remove the pages
      // above it first.
      final last = _entries.last;
      final holder = _controllerOf(router, last.pageId);
      if (holder is StackRouter) holder.removeUntil((data) => data.route.id == last.pageId);
      router.navigateAll([last.route]).whenComplete(() => _isNavigatingBack = false);
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

  // The id of the page on top, which tells apart two pages with the same url.
  final LocalKey pageId;

  const _HistoryEntry(this.route, this.url, this.pageId);

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
