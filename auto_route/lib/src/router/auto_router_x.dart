import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart' show BuildContext, optionalTypeArgs;

/// An extension that provides common routing helpers
/// on [BuildContext]
extension AutoRouterX on BuildContext {
  /// Helper to read the scoped router
  StackRouter get router => AutoRouter.of(this);

  /// Helper to watch the scoped router
  StackRouter get watchRouter => AutoRouter.of(this, watch: true);

  /// see [StackRouter.push]
  @optionalTypeArgs
  Future<T?> pushRoute<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) =>
      router.push<T>(route, onFailure: onFailure);

  /// see [StackRouter.replace]
  @optionalTypeArgs
  Future<T?> replaceRoute<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) =>
      router.replace<T>(route, onFailure: onFailure);

  /// see [StackRouter.maybePop]
  @optionalTypeArgs
  @Deprecated('Renamed to maybePop to avoid confusion')
  Future<bool> popRoute<T extends Object?>([T? result]) =>
      router.maybePop<T>(result);

  /// see [StackRouter.maybePop]
  @optionalTypeArgs
  Future<bool> maybePop<T extends Object?>([T? result]) =>
      router.maybePop<T>(result);

  /// see [RoutingController.navigate]
  Future<void> navigateTo(PageRouteInfo route,
          {OnNavigationFailure? onFailure}) =>
      RouterScope.of(this).controller.navigate(
            route,
            onFailure: onFailure,
          );

  /// see [RoutingController.back]
  void back() => RouterScope.of(this).controller.back();

  /// see [RoutingController.navigateNamed]
  Future<void> navigateNamedTo(String path,
          {bool includePrefixMatches = false,
          OnNavigationFailure? onFailure}) =>
      RouterScope.of(this).controller.navigateNamed(
            path,
            includePrefixMatches: includePrefixMatches,
            onFailure: onFailure,
          );

  /// Helper to read the scoped [TabsRouter]
  TabsRouter get tabsRouter => AutoTabsRouter.of(this);

  /// Helper to watch the scoped [TabsRouter]
  TabsRouter get watchTabsRouter => AutoTabsRouter.of(this, watch: true);

  /// Returns the top most rendered route
  RouteData get topRoute => watchRouter.topRoute;

  /// Returns the top most match rendered or pending
  RouteMatch get topRouteMatch => watchRouter.topMatch;

  /// see [RoutingController.innerRouterOf]
  T? innerRouterOf<T extends RoutingController>(String routeKey) =>
      RouterScope.of(this).controller.innerRouterOf<T>(routeKey);

  /// Helper to read the scoped [RouteData] of a route
  RouteData get routeData => RouteData.of(this);
}
