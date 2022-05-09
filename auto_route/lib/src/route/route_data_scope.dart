import 'package:flutter/material.dart';

import '../../auto_route.dart';

class RouteDataScope extends InheritedWidget {
  final RouteData routeData;

  const RouteDataScope({
    Key? key,
    required this.routeData,
    required Widget child,
  }) : super(child: child, key: key);

  static RouteDataScope of(BuildContext context) {
    var scope = context.findAncestorWidgetOfExactType<RouteDataScope>();
    assert(() {
      if (scope == null) {
        throw FlutterError(
            'RouteData operation requested with a context that does not include an RouteData.\n'
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
}
