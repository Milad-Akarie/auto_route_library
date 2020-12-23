import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route/annotations.dart';
import 'package:auto_route_generator/import_resolver.dart';
import 'package:auto_route_generator/route_config_resolver.dart';
import 'package:source_gen/source_gen.dart';

import '../utils.dart';

/// Extracts and holds router configs
/// to be used in [RouterClassGenerator]

class RouterConfig {
  final bool generateNavigationHelper;
  final List<RouteConfig> routes;
  final RouteConfig globalRouteConfig;
  final String routesClassName;
  final String routeNamePrefix;
  final bool usesLegacyGenerator;
  final String routerClassName;
  final RouterConfig parent;
  final String replaceInRouteName;
  final ClassElement element;

  RouterConfig({
    this.generateNavigationHelper,
    this.routes,
    this.parent,
    this.element,
    this.globalRouteConfig,
    this.routesClassName,
    this.usesLegacyGenerator,
    this.routeNamePrefix,
    this.routerClassName,
    this.replaceInRouteName,
  });

  RouterConfig copyWith({
    bool generateNavigationHelper,
    List<RouteConfig> routes,
    RouteConfig globalRouteConfig,
    String routesClassName,
    String routeNamePrefix,
    String routerClassName,
    RouterConfig parent,
    String replaceInRouteName,
    ClassElement element,
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

  List<RouterConfig> get subRouters => routes
      .where((e) => e.childRouterConfig != null)
      .map((e) => e.childRouterConfig)
      .toList();

  List<RouterConfig> get collectAllRoutersIncludingParent => subRouters.fold(
      [this], (all, e) => all..addAll(e.collectAllRoutersIncludingParent));

  @override
  String toString() {
    return 'RouterConfig{routes: $routes, routesClassName: $routesClassName, routerClassName: $routerClassName}';
  }
}

class RouterConfigResolver {
  final TypeResolver _typeResolver;

  RouterConfigResolver(this._typeResolver);

  RouterConfig resolve(ConstantReader autoRouter, ClassElement clazz) {
    /// ensure router config classes are prefixed with $
    /// to use the stripped name for the generated class
    throwIf(
      !clazz.displayName.startsWith(r'$'),
      'Router class name must be prefixed with \$',
      element: clazz,
    );

    var globalRouteConfig = RouteConfig();
    if (autoRouter.instanceOf(TypeChecker.fromRuntime(CupertinoAutoRouter))) {
      globalRouteConfig.routeType = RouteType.cupertino;
    } else if (autoRouter
        .instanceOf(TypeChecker.fromRuntime(AdaptiveAutoRouter))) {
      globalRouteConfig.routeType = RouteType.adaptive;
    } else if (autoRouter
        .instanceOf(TypeChecker.fromRuntime(CustomAutoRouter))) {
      globalRouteConfig.routeType = RouteType.custom;
      globalRouteConfig.durationInMilliseconds =
          autoRouter.peek('durationInMilliseconds')?.intValue;
      globalRouteConfig.customRouteOpaque =
          autoRouter.peek('opaque')?.boolValue;
      globalRouteConfig.customRouteBarrierDismissible =
          autoRouter.peek('barrierDismissible')?.boolValue;
      final function =
          autoRouter.peek('transitionsBuilder')?.objectValue?.toFunctionValue();

      if (function != null) {
        globalRouteConfig.transitionBuilder =
            _typeResolver.resolveImportableFunctionType(function);
      }

      final customRouteBuilder =
          autoRouter.peek('customRouteBuilder')?.objectValue?.toFunctionValue();

      if (customRouteBuilder != null) {
        globalRouteConfig.customRouteBuilder =
            _typeResolver.resolveImportableFunctionType(customRouteBuilder);
      }
    }

    var generateNavigationExt =
        autoRouter.peek('generateNavigationHelperExtension')?.boolValue ??
            false;
    var routeNamePrefix = autoRouter.peek('routePrefix')?.stringValue ?? '/';
    var routesClassName =
        autoRouter.peek('routesClassName')?.stringValue ?? 'Routes';

    var usesLegacyGenerator =
        autoRouter.peek('usesLegacyGenerator')?.boolValue ?? false;
    var replaceInRouteName = autoRouter.peek('replaceInRouteName')?.stringValue;

    final autoRoutes = autoRouter.read('routes').listValue;

    var routerConfig = RouterConfig(
        globalRouteConfig: globalRouteConfig,
        routerClassName: clazz.displayName.substring(1),
        element: clazz,
        routesClassName: routesClassName,
        routeNamePrefix: routeNamePrefix,
        generateNavigationHelper: generateNavigationExt,
        usesLegacyGenerator: usesLegacyGenerator,
        replaceInRouteName: replaceInRouteName);

    var routes = _resolveRoutes(routerConfig, autoRoutes);
    return routerConfig.copyWith(routes: routes);
  }

  List<RouteConfig> _resolveRoutes(
      RouterConfig routerConfig, List<DartObject> routesList) {
    var routeResolver = RouteConfigResolver(routerConfig, _typeResolver);
    final routes = <RouteConfig>[];
    for (var entry in routesList) {
      var routeReader = ConstantReader(entry);
      RouteConfig route;
      route = routeResolver.resolve(routeReader);
      routes.add(route);

      var children = routeReader.peek('children')?.listValue;
      if (children?.isNotEmpty == true) {
        var name = capitalize(valueOr(route.name, route.className));
        var subRouterConfig = routerConfig.copyWith(
          routerClassName: '${name}Router',
          routesClassName: '${name}Routes',
          parent: routerConfig,
        );
        var routes = _resolveRoutes(subRouterConfig, children);
        route.childRouterConfig = subRouterConfig.copyWith(routes: routes);
      }
    }
    return routes;
  }
}
