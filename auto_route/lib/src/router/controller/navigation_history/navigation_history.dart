import 'package:auto_route/src/router/controller/navigation_history/navigation_history_base.dart';
import 'package:auto_route/src/router/controller/routing_controller.dart' show StackRouter;

/// A stub implementation of [NavigationHistory]
class NavigationHistoryImpl extends NavigationHistory {
  /// Default constructor
  // A stub for conditional imports: its constructor matches the real ones.
  // ignore: avoid_unused_constructor_parameters
  NavigationHistoryImpl(StackRouter router);

  @override
  void back() {
    throw Exception('Stub implementation');
  }

  @override
  bool get canNavigateBack => throw Exception('Stub implementation');

  @override
  void forward() {
    throw Exception('Stub implementation');
  }

  @override
  int get length => throw Exception('Stub implementation');

  @override
  StackRouter get router => throw Exception('Stub implementation');

  @override
  // Overrides a nullable getter.
  // ignore: avoid-unnecessary-nullable-return-type
  Object? get pathState => throw Exception('Stub implementation');

  @override
  void pushPathState(Object? state) {
    throw Exception('Stub implementation');
  }
}
