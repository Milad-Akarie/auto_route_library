import 'package:auto_route/src/router/controller/routing_controller.dart' show StackRouter;

import 'navigation_history_base.dart';

/// A stub implementation of [NavigationHistory]
class NavigationHistoryImpl extends NavigationHistory {
  /// Default constructor
  NavigationHistoryImpl(StackRouter router);

  @override
  void back() {
    throw Exception("Stub implementation");
  }

  @override
  bool get canNavigateBack => throw Exception("Stub implementation");

  @override
  void forward() {
    throw Exception("Stub implementation");
  }

  @override
  int get length => throw Exception("Stub implementation");

  @override
  StackRouter get router => throw Exception("Stub implementation");

  @override
  Object? get pathState => throw Exception("Stub implementation");

  @override
  void pushPathState(Object? state) {
    throw Exception("Stub implementation");
  }
}
