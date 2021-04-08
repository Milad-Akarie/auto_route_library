import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

import 'route_data_scope.dart';

class RouteData {
  PageRouteInfo route;
  final RouteData? parent;
  final RouteConfig config;
  final ValueKey<String> key;

  RouteData({
    required this.route,
    this.parent,
    required this.config,
    required this.key,
  });

  List<RouteData> get breadcrumbs => List.unmodifiable([
        if (parent != null) ...parent!.breadcrumbs,
        this,
      ]);

  static RouteData of(BuildContext context) {
    return RouteDataScope.of(context);
  }

  T argsAs<T>({T Function()? orElse}) {
    final args = route.args;
    if (args == null) {
      if (orElse == null) {
        throw FlutterError('${T.toString()} can not be null because it has a required parameter');
      } else {
        return orElse();
      }
    } else if (args is! T) {
      throw FlutterError('Expected [${T.toString()}],  found [${args.runtimeType}]');
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

  void updateActiveChild(RouteData child) {
    route = route.updateChildren(children: [child.route]);
  }
}
