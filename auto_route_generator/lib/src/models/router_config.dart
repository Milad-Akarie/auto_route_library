import 'package:analyzer/dart/element/element.dart' show ClassElement;

import 'route_config.dart';

class RouterConfig {
  final List<RouteConfig> routes;
  final RouteConfig parentRouteConfig;
  final String routerClassName;
  final RouterConfig? parent;
  final String? replaceInRouteName;
  final ClassElement element;
  final bool deferredLoading;

  RouterConfig({
    required this.routes,
    required this.element,
    required this.parentRouteConfig,
    required this.routerClassName,
    this.parent,
    this.replaceInRouteName,
    this.deferredLoading = false,
  });

  RouterConfig copyWith({
    bool? generateNavigationHelper,
    List<RouteConfig>? routes,
    RouteConfig? parentRouteConfig,
    String? routesClassName,
    String? routeNamePrefix,
    String? routerClassName,
    RouterConfig? parent,
    String? replaceInRouteName,
    ClassElement? element,
    bool? deferredLoading,
  }) {
    return RouterConfig(
      routes: routes ?? this.routes,
      parentRouteConfig: parentRouteConfig ?? this.parentRouteConfig,
      routerClassName: routerClassName ?? this.routerClassName,
      replaceInRouteName: replaceInRouteName ?? this.replaceInRouteName,
      parent: parent ?? this.parent,
      element: this.element,
      deferredLoading: deferredLoading ?? this.deferredLoading,
    );
  }

  List<RouterConfig> get subRouters {
    final routers = <RouterConfig>[];
    routes.forEach((route) {
      if (route.childRouterConfig != null) {
        routers.add(route.childRouterConfig!);
      }
    });
    return routers;
  }

  List<RouterConfig> get collectAllRoutersIncludingParent => subRouters.fold(
      [this], (all, e) => all..addAll(e.collectAllRoutersIncludingParent));
}
