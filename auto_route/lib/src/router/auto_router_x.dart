import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart' show BuildContext, optionalTypeArgs;

import '../navigation_failure.dart';
import 'controller/routing_controller.dart';
import 'widgets/auto_router.dart';

extension AutoRouterX on BuildContext {
  StackRouter get router => AutoRouter.of(this);

  @optionalTypeArgs
  Future<T?> pushRoute<T extends Object?>(PageRouteInfo route,
          {OnNavigationFailure? onFailure}) =>
      router.push<T>(route, onFailure: onFailure);

  @optionalTypeArgs
  Future<T?> replaceRoute<T extends Object?>(PageRouteInfo route,
          {OnNavigationFailure? onFailure}) =>
      router.replace<T>(route, onFailure: onFailure);

  @optionalTypeArgs
  Future<bool> popRoute<T extends Object?>([T? result]) =>
      router.pop<T>(result);

  Future<void> navigateTo(PageRouteInfo route,
          {OnNavigationFailure? onFailure}) =>
      RouterScope.of(this).controller.navigate(
            route,
            onFailure: onFailure,
          );
  Future<void> navigateNamedTo(String path,
          {bool includePrefixMatches = false,
          OnNavigationFailure? onFailure}) =>
      RouterScope.of(this).controller.navigateNamed(
            path,
            includePrefixMatches: includePrefixMatches,
            onFailure: onFailure,
          );

  TabsRouter get tabsRouter => AutoTabsRouter.of(this);
  RouteData get topRoute => router.topRoute;

  T? innerRouterOf<T extends RoutingController>(String routeKey) =>
      RouterScope.of(this).controller.innerRouterOf<T>(routeKey);

  RouteData get routeData => RouteData.of(this);
}
