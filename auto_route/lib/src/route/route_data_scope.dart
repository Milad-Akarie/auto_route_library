import 'package:flutter/material.dart';

import '../../auto_route.dart';

class RouteDataScope extends InheritedWidget {
  final RouteData routeData;
  final int segmentsHash;

  const RouteDataScope({
    required this.routeData,
    required Widget child,
    required this.segmentsHash,
  }) : super(child: child);

  static RouteData of(BuildContext context) {
    var scope = context.dependOnInheritedWidgetOfExactType<RouteDataScope>();
    assert(() {
      if (scope == null) {
        throw FlutterError(
            'RouteData operation requested with a context that does not include an RouteData.\n'
            'The context used to retrieve the RouteData must be that of a widget that '
            'is a descendant of a AutoRoutePage.');
      }
      return true;
    }());
    return scope!.routeData;
  }

  @override
  bool updateShouldNotify(covariant RouteDataScope oldWidget) {
    return segmentsHash != oldWidget.segmentsHash;
  }
}
