import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

class AutoRouterObserver extends NavigatorObserver {
  void didInitTabRoute(TabPageRoute route, TabPageRoute? previousRoute) {}
  void didChangeTabRoute(TabPageRoute route, TabPageRoute previousRoute) {}
}

class TabPageRoute {
  final PageRouteInfo routeInfo;

  final int index;
  const TabPageRoute({
    required this.routeInfo,
    required this.index,
  });

  String get name => routeInfo.routeName;
  String get path => routeInfo.path;
  String get match => routeInfo.stringMatch;
}
