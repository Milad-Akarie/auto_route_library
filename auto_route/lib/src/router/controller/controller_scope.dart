import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

part 'stack_router_scope.dart';
part 'tabs_router_scope.dart';

/// Injects the given [RoutingController] to context
/// so it can be looked up by any child widget
@protected
class RouterScope extends InheritedWidget {
  /// Default constructor
  const new({
    required super.child,
    required this.controller,
    required this.inheritableObserversBuilder,
    required this.stateHash,
    super.key,
    this.navigatorObservers = const [],
  });

  /// The controller to inject
  final RoutingController controller;

  /// The builder contains all inherited observers builders from all
  /// ancestors [RouterScope]s
  final NavigatorObserversBuilder inheritableObserversBuilder;

  /// The state snapshot calculated by [controller]
  /// duration the build of this widget
  ///
  /// it's used to track the changes of [controller] state
  final int stateHash;

  /// The list of inherited observer from all
  /// ancestors [RouterScope]s
  final List<NavigatorObserver> navigatorObservers;

  /// Looks up and returns the scoped [controller]
  ///
  /// if watch is true dependent widget will watch changes
  /// of this scope otherwise it would just read it
  ///
  /// throws an error if it does not find it
  static RouterScope of(BuildContext context, {bool watch = false}) {
    RouterScope? scope;
    if (watch) {
      scope = context.dependOnInheritedWidgetOfExactType<RouterScope>();
    } else {
      scope = context.findAncestorWidgetOfExactType<RouterScope>();
    }
    if (kDebugMode && scope == null) {
      throw FlutterError(
        'RouterScope operation requested with a context that does not include a RouterScope.\n'
        'The context used to retrieve the Router must be that of a widget that '
        'is a descendant of a RouterScope widget.',
      );
    }
    return scope!;
  }

  /// Looks up the first observer of type [T]
  ///
  /// returns null if it can't find it
  T? firstObserverOfType<T extends NavigatorObserver>() {
    final typedObservers = navigatorObservers.whereType<T>();
    if (typedObservers.isNotEmpty) {
      return typedObservers.first;
    }
    return null;
  }

  @override
  bool updateShouldNotify(covariant RouterScope oldWidget) {
    return stateHash != oldWidget.stateHash;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<RoutingController>('controller', controller))
      ..add(
        DiagnosticsProperty<NavigatorObserversBuilder>(
          'inheritableObserversBuilder',
          inheritableObserversBuilder,
        ),
      )
      ..add(DiagnosticsProperty<int>('stateHash', stateHash));
  }
}
