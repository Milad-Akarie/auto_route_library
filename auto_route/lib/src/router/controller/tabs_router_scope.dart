part of 'controller_scope.dart';

/// Injects the given [TabsRouter] to context
/// so it can be looked up by any child widget
class TabsRouterScope extends InheritedWidget {
  /// Default constructor
  const new({required super.child, required this.stateHash, required this.controller, super.key});

  /// The controller to inject
  final TabsRouter controller;

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
  static TabsRouterScope? of(BuildContext context, {bool watch = false}) {
    if (watch) {
      return context.dependOnInheritedWidgetOfExactType();
    }
    return context.findAncestorWidgetOfExactType();
  }

  @override
  bool updateShouldNotify(covariant TabsRouterScope oldWidget) {
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
