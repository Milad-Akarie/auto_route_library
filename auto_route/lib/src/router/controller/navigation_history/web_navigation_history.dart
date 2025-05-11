import 'dart:js_interop';

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

  @override
  void back() {
    _history.back();
  }

  int get _currentIndex {
    final state = _history.state.dartify();
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

  @override
  void pushPathState(Object? state) {
    onNewUrlState(urlState.copyWith(pathState: state));
  }

  @override
  Object? get pathState => urlState.pathState;
}
