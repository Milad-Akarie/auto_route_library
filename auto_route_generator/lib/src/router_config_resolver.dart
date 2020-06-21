import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route/auto_route_annotations.dart';
import 'package:auto_route_generator/import_resolver.dart';
import 'package:auto_route_generator/route_config_resolver.dart';
import 'package:build/build.dart';
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
  final String routerClassName;

  RouterConfig({
    this.generateNavigationHelper,
    this.routes,
    this.globalRouteConfig,
    this.routesClassName,
    this.routeNamePrefix,
    this.routerClassName,
  });

  RouterConfig copyWith({
    bool generateNavigationHelper,
    List<RouteConfig> routes,
    RouteConfig globalRouteConfig,
    String routesClassName,
    String routeNamePrefix,
    String routerClassName,
  }) {
    return RouterConfig(
      generateNavigationHelper: generateNavigationHelper ?? this.generateNavigationHelper,
      routes: routes ?? this.routes,
      globalRouteConfig: globalRouteConfig ?? this.globalRouteConfig,
      routesClassName: routesClassName ?? this.routesClassName,
      routeNamePrefix: routeNamePrefix ?? this.routeNamePrefix,
      routerClassName: routerClassName ?? this.routerClassName,
    );
  }

  List<RouterConfig> get subRoutes => routes.where((e) => e.routerConfig != null).map((e) => e.routerConfig).toList();

  List<RouterConfig> get collectAllRoutersIncludingParent =>
      subRoutes.fold([this], (all, e) => all..addAll(e.collectAllRoutersIncludingParent));

  @override
  String toString() {
    return 'RouterConfig{routes: $routes, routesClassName: $routesClassName, routerClassName: $routerClassName}';
  }
}

class RouterConfigResolver {
  final Resolver _resolver;

  RouterConfigResolver(this._resolver);

  Future<RouterConfig> resolve(ConstantReader autoRouter, ClassElement clazz) async {
    // ensure router config classes are prefixed with $
    // to use the stripped name for the generated class
    throwIf(
      !clazz.displayName.startsWith(r'$'),
      'Router class name must be prefixed with \$',
      element: clazz,
    );

    var globalRouteConfig = RouteConfig();
    if (autoRouter.instanceOf(TypeChecker.fromRuntime(CupertinoAutoRouter))) {
      globalRouteConfig.routeType = RouteType.cupertino;
    } else if (autoRouter.instanceOf(TypeChecker.fromRuntime(AdaptiveAutoRouter))) {
      globalRouteConfig.routeType = RouteType.adaptive;
    } else if (autoRouter.instanceOf(TypeChecker.fromRuntime(CustomAutoRouter))) {
      globalRouteConfig.routeType = RouteType.custom;
      globalRouteConfig.durationInMilliseconds = autoRouter.peek('durationInMilliseconds')?.intValue;
      globalRouteConfig.customRouteOpaque = autoRouter.peek('opaque')?.boolValue;
      globalRouteConfig.customRouteBarrierDismissible = autoRouter.peek('barrierDismissible')?.boolValue;
      final function = autoRouter.peek('transitionsBuilder')?.objectValue?.toFunctionValue();
      if (function != null) {
        final displayName = function.displayName.replaceFirst(RegExp('^_'), '');
        final functionName = (function.isStatic && function.enclosingElement?.displayName != null)
            ? '${function.enclosingElement.displayName}.$displayName'
            : displayName;

        var import;
        if (function.enclosingElement?.name != 'TransitionsBuilders') {
          import = getImport(function);
        }
        globalRouteConfig.transitionBuilder = CustomTransitionBuilder(functionName, import);
      }
    }
    var generateNavigationExt = autoRouter.peek('generateNavigationHelperExtension')?.boolValue ?? false;
    var routeNamePrefix = autoRouter.peek('routePrefix')?.stringValue ?? '/';
    var routesClassName = autoRouter.peek('routesClassName')?.stringValue ?? 'Routes';

    final autoRoutes = autoRouter.read('routes').listValue;

    var routerConfig = RouterConfig(
      globalRouteConfig: globalRouteConfig,
      routerClassName: clazz.displayName.substring(1),
      routesClassName: routesClassName,
      routeNamePrefix: routeNamePrefix,
      generateNavigationHelper: generateNavigationExt,
    );

    var routes = await _resolveRoutes(routerConfig, autoRoutes);
    return routerConfig.copyWith(routes: routes);
  }

  Future<List<RouteConfig>> _resolveRoutes(RouterConfig routerConfig, List<DartObject> routesList) async {
    var routeResolver = RouteConfigResolver(routerConfig, _resolver);
    final routes = <RouteConfig>[];
    for (var entry in routesList) {
      var routeReader = ConstantReader(entry);
      RouteConfig route;
      route = await routeResolver.resolve(routeReader);
      routes.add(route);

      var children = routeReader.peek('children')?.listValue;
      if (children?.isNotEmpty == true) {
        var name = capitalize(route.name);
        var subRouterConfig = routerConfig.copyWith(
          routerClassName: '${name}Router',
          routesClassName: '${name}Routes',
        );
        var routes = await _resolveRoutes(subRouterConfig, children);
        route.routerConfig = subRouterConfig.copyWith(routes: routes);
      }
    }
    return routes;
  }
}
