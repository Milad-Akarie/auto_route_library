import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart' show BuildContext;

import '../navigation_failure.dart';
import 'controller/routing_controller.dart';
import 'widgets/auto_router.dart';

extension AutoRouterX on BuildContext {
  StackRouter get router => AutoRouter.of(this);

  Future<void> pushRoute(PageRouteInfo route, {OnNavigationFailure? onFailure}) =>
      router.push(route, onFailure: onFailure);

  Future<void> replaceRoute(PageRouteInfo route, {OnNavigationFailure? onFailure}) =>
      router.replace(route, onFailure: onFailure);

  Future<bool> popRoute() => router.pop();

  TabsRouter get tabsRouter => AutoTabsRouter.of(this);

  RoutingController? innerRouterOf(String routeKey) => AutoRouter.innerRouterOf(this, routeKey);

  @Deprecated('Use routeData instead')
  RouteData? get route => RouteData.of(this);

  RouteData get routeData => RouteData.of(this);
}
