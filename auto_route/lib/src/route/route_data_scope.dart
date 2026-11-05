import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// Injects the given [routeData] to context
/// so it can be looked up by any child widget
class RouteDataScope extends InheritedWidget {
  /// Default reconstruct
  const new({required this.routeData, required super.child, super.key});

  /// The route data to be scoped
  final RouteData<Object?> routeData;

  /// Looks up and returns the scoped [routeData]
  ///
  /// throws an error if it does not find it
  static RouteDataScope of(BuildContext context) {
    final scope = context.findAncestorWidgetOfExactType<RouteDataScope>();
    if (kDebugMode && scope == null) {
      throw FlutterError(
        'RouteData operation requested with a context that does not '
        'include an RouteData.\n'
        'The context used to retrieve the RouteData must be that of a '
        'widget that '
        'is a descendant of a AutoRoutePage.',
      );
    }
    return scope!;
  }

  @override
  bool updateShouldNotify(covariant RouteDataScope oldWidget) {
    return routeData.route != oldWidget.routeData.route;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<RouteData<Object?>>('routeData', routeData),
    );
  }
}
