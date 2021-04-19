import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

import 'route_data_scope.dart';

class RouteData {
  PageRouteInfo _route;
  final RouteData? parent;
  final RouteConfig? config;
  final ValueKey<String> key;

  RouteData? activeChild;

  RouteData({
    required PageRouteInfo route,
    this.parent,
    this.config,
    required this.key,
  }) : _route = route {
    if (route.hasInitialChildren) {
      activeChild = RouteData(
        route: route.initialChildren!.last,
        parent: this,
        key: ValueKey(route.initialChildren!.last.stringMatch),
      );
    }
  }

  List<PageRouteInfo> get breadcrumbs => List.unmodifiable([
        if (parent != null) ...parent!.breadcrumbs,
        _route,
      ]);

  List<PageRouteInfo> get segments {
    print("Getting segments [$name]  active child ${activeChild?.name}");
    return List.unmodifiable([
      _route,
      if (activeChild != null) ...activeChild!.segments,
    ]);
  }

  static RouteData of(BuildContext context) {
    return RouteDataScope.of(context);
  }

  T argsAs<T>({T Function()? orElse}) {
    final args = _route.args;
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

  PageRouteInfo get route => _route;

  String get name => _route.routeName;

  String get path => _route.path;

  String get match => _route.stringMatch;

  Parameters get pathParams => Parameters(_route.params);

  Parameters get queryParams => Parameters(_route.queryParams);

  String? get fragment => _route.match?.fragment;

  void updateRoute(PageRouteInfo route) {
    _route = route;
  }
}
