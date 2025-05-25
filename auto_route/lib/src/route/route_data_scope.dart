import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../auto_route.dart';

/// Injects the given [routeData] to context
/// so it can be looked up by any child widget
class RouteDataScope extends InheritedWidget {
  /// The route data to be scoped
  final RouteData routeData;

  /// Default reconstruct
  const RouteDataScope({
    super.key,
    required this.routeData,
    required super.child,
  });

  /// Looks up and returns the scoped [routeData]
  ///
  /// throws an error if it does not find it
  static RouteDataScope of(BuildContext context) {
    var scope = context.findAncestorWidgetOfExactType<RouteDataScope>();
    assert(() {
      if (scope == null) {
        throw FlutterError('RouteData operation requested with a context that does not include an RouteData.\n'
            'The context used to retrieve the RouteData must be that of a widget that '
            'is a descendant of a AutoRoutePage.');
      }
      return true;
    }());
    return scope!;
  }

  @override
  bool updateShouldNotify(covariant RouteDataScope oldWidget) {
    return routeData.route != oldWidget.routeData.route;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<RouteData>('routeData', routeData));
  }
}
