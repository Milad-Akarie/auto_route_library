import 'package:analyzer/dart/element/element.dart' show ClassElement;
import 'route_config.dart';

class RouterConfig {
  final bool generateNavigationHelper;
  final List<RouteConfig> routes;
  final RouteConfig globalRouteConfig;
  final String? routesClassName;
  final String? routeNamePrefix;
  final bool usesLegacyGenerator;
  final String routerClassName;
  final RouterConfig? parent;
  final String? replaceInRouteName;
  final ClassElement element;

  RouterConfig({
    required this.generateNavigationHelper,
    required this.routes,
    required this.element,
    required this.globalRouteConfig,
    required this.usesLegacyGenerator,
    required this.routerClassName,
    this.routesClassName,
    this.parent,
    this.routeNamePrefix,
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
      generateNavigationHelper:
          generateNavigationHelper ?? this.generateNavigationHelper,
      routes: routes ?? this.routes,
      globalRouteConfig: globalRouteConfig ?? this.globalRouteConfig,
      routesClassName: routesClassName ?? this.routesClassName,
      routeNamePrefix: routeNamePrefix ?? this.routeNamePrefix,
      routerClassName: routerClassName ?? this.routerClassName,
      replaceInRouteName: replaceInRouteName ?? this.replaceInRouteName,
      parent: parent ?? this.parent,
      element: this.element,
      usesLegacyGenerator: this.usesLegacyGenerator,
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

  @override
  String toString() {
    return 'RouterConfig{routes: $routes, routesClassName: $routesClassName, routerClassName: $routerClassName}';
  }
}
