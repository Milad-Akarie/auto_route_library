part of 'routing_controller.dart';

abstract class NavigationHistory {
  NavigationHistory() {
    _router.addListener(() {
      _onNewUrlState(UrlState.fromSegments(
        _router.currentSegments,
        shouldReplace: _isUrlStateMarkedForReplace,
      ));
      _unMarkUrlStateForReplace();
    });
  }

  bool _isUrlStateMarkedForReplace = false;

  bool get isUrlStateMarkedForReplace => _isUrlStateMarkedForReplace;

  void markUrlStateForReplace() => _isUrlStateMarkedForReplace = true;

  void _unMarkUrlStateForReplace() => _isUrlStateMarkedForReplace = false;

  UrlState _urlState = UrlState.fromSegments([]);

  void _onNewUrlState(UrlState newState) {
    _urlState = newState;
  }

  bool isRouteActive(String routeName) {
    return urlState.segments.any(
      (r) => r.name == routeName,
    );
  }

  bool isRouteKeyActive(Key key) {
    return urlState.segments.any(
      (r) => r.key == key,
    );
  }

  bool isPathActive(String pattern) {
    return RegExp(pattern).hasMatch(urlState.path);
  }

  UrlState get urlState => _urlState;

  StackRouter get _router;

  bool get canNavigateBack;

  int get length;

  void back();

  void forward();
}

class WebNavigationHistory extends NavigationHistory {
  WebNavigationHistory(this._router);

  @override
  final StackRouter _router;

  final _history = html.window.history;

  @override
  void back() => _history.back();

  int get _currentIndex {
    final state = _history.state;
    if (state is Map) {
      return state['serialCount'] ?? 0;
    }
    return 0;
  }

  @override
  bool get canNavigateBack => _currentIndex > 0;

  @override
  void forward() => _history.forward();

  @override
  int get length => _history.length;
}

class _HistoryEntry {
  final RouteMatch route;
  final String url;

  const _HistoryEntry(this.route, this.url);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _HistoryEntry &&
          runtimeType == other.runtimeType &&
          url == other.url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() {
    return route.flattened.map((e) => e.name).join('->');
  }
}

class NativeNavigationHistory extends NavigationHistory {
  NativeNavigationHistory(this._router);

  @override
  final StackRouter _router;

  final _entries = <_HistoryEntry>[];

  @override
  void _onNewUrlState(UrlState newState) {
    super._onNewUrlState(newState);

    if (newState.shouldReplace && length > 0) {
      _entries.removeLast();
    }

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

    RouteMatch toHierarchy(List<RouteMatch> segments) {
      if (segments.length == 1) {
        return segments.first;
      } else {
        return segments.first.copyWith(children: [
          toHierarchy(
            segments.sublist(1, segments.length),
          ),
        ]);
      }
    }

    final route = toHierarchy(urlState.segments);
    final entryIndex = _entries.lastIndexWhere(
      (e) => e.url == urlState.url,
    );

    if (entryIndex != -1) {
      _entries.removeRange(entryIndex, _entries.length);
    }
    _entries.add(_HistoryEntry(route, urlState.url));
  }

  @override
  void back() {
    if (canNavigateBack) {
      _entries.removeLast();
      _router.navigateAll([_entries.last.route]);
    }
  }

  @override
  void forward() {
    throw FlutterError(
        'forward navigation is not supported for non-web platforms');
  }
}
