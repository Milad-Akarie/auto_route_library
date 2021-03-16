import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

import 'entry_scope.dart';

class RouteData {
  final PageRouteInfo route;
  final RouteData? parent;
  final RouteConfig config;

  const RouteData({
    required this.route,
    this.parent,
    required this.config,
  });

  List<RouteData> get breadcrumbs => List.unmodifiable([
        if (parent != null) ...parent!.breadcrumbs,
        this,
      ]);

  static RouteData of(BuildContext context) {
    var scope = context.dependOnInheritedWidgetOfExactType<StackEntryScope>();
    assert(() {
      if (scope == null) {
        throw FlutterError(
            'RouteData operation requested with a context that does not include an RouteData.\n'
            'The context used to retrieve the RouteData must be that of a widget that '
            'is a descendant of a AutoRoutePage.');
      }
      return true;
    }());
    return scope!.entry.routeData;
  }

  T argsAs<T>({T Function()? orElse}) {
    final args = route.args;
    if (args == null) {
      if (orElse == null) {
        throw FlutterError(
            '${T.toString()} can not be null because it has a required parameter');
      } else {
        return orElse();
      }
    } else if (args is! T) {
      throw FlutterError(
          'Expected [${T.toString()}],  found [${args.runtimeType}]');
    } else {
      return args;
    }
  }

  String get name => route.routeName;

  String get path => route.path;

  String get match => route.stringMatch;

  Parameters get pathParams => Parameters(route.params);

  Parameters get queryParams => Parameters(route.queryParams);

  String? get fragment => route.match?.fragment;
}
