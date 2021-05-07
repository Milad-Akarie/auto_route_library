import 'package:analyzer/dart/element/element.dart' show ClassElement;
import 'route_config.dart';

class RouterConfig {
  final List<RouteConfig> routes;
  final RouteConfig globalRouteConfig;
  final String routerClassName;
  final RouterConfig? parent;
  final String? replaceInRouteName;
  final ClassElement element;

  RouterConfig({
    required this.routes,
    required this.element,
    required this.globalRouteConfig,
    required this.routerClassName,
    this.parent,
    this.replaceInRouteName,
  });

  RouterConfig copyWith({
    bool? generateNavigationHelper,
    List<RouteConfig>? routes,
    RouteConfig? globalRouteConfig,
    String? routesClassName,
    String? routeNamePrefix,
    String? routerClassName,
    RouterConfig? parent,
    String? replaceInRouteName,
    ClassElement? element,
  }) {
    return RouterConfig(
      routes: routes ?? this.routes,
      globalRouteConfig: globalRouteConfig ?? this.globalRouteConfig,
      routerClassName: routerClassName ?? this.routerClassName,
      replaceInRouteName: replaceInRouteName ?? this.replaceInRouteName,
      parent: parent ?? this.parent,
      element: this.element,
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
