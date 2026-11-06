part of 'router_scope.dart';

/// Injects the given [StackRouter] to context
/// so it can be looked up by any child widget
class StackRouterScope extends InheritedWidget {
  /// Default constructor
  const new({
    required super.child,
    required this.controller,
    required this.stateHash,
    super.key,
  });

  /// The controller to inject
  final StackRouter controller;

  /// The state snapshot calculated by [controller]
  /// duration the build of this widget
  ///
  /// it's used to track the changes of [controller] state
  final int stateHash;

  /// Looks up and returns the scoped [controller]
  ///
  /// if watch is true dependent widget will watch changes
  /// of this scope otherwise it would just read it
  ///
  /// returns null if it does not find it
  static StackRouterScope? of(BuildContext context, {bool watch = false}) {
    if (watch) {
      return context.dependOnInheritedWidgetOfExactType();
    }
    return context.findAncestorWidgetOfExactType();
  }

  @override
  bool updateShouldNotify(covariant StackRouterScope oldWidget) {
    return stateHash != oldWidget.stateHash;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<RoutingController>('controller', controller))
      ..add(DiagnosticsProperty<int>('stateHash', stateHash));
  }
}
