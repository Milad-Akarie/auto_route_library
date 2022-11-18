import 'package:auto_route/auto_route.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'navigation_history_base.dart';

class NavigationHistoryImpl extends NavigationHistory {
  NavigationHistoryImpl(this.router);

  @override
  final StackRouter router;

  final _history = html.window.history;

  @override
  void back() {
    _history.back();
  }

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
