import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route/annotations.dart';
import 'package:auto_route_generator/src/models/route_parameter_config.dart';
import 'package:source_gen/source_gen.dart';

import '../../utils.dart';
import '../models/importable_type.dart';
import '../models/route_config.dart';
import '../models/router_config.dart';
import 'route_config_resolver.dart';
import 'type_resolver.dart';

/// Extracts and holds router configs

class RouterConfigResolver {
  final TypeResolver _typeResolver;
  late RouteConfig _globalRouteConfig;

  RouterConfigResolver(this._typeResolver);

  RouterConfig resolve(ConstantReader autoRouter, ClassElement clazz,
      {bool usesPartBuilder = false}) {
    /// ensure router config classes are prefixed with $
    /// to use the stripped name for the generated class
    throwIf(
      !usesPartBuilder && !clazz.displayName.startsWith(r'$'),
      'Router class name must be prefixed with \$',
      element: clazz,
    );

    int routeType = RouteType.material;
    int? durationInMilliseconds;
    int? reverseDurationInMilliseconds;
    bool? customRouteOpaque;
    bool? customRouteBarrierDismissible;
    ResolvedType? transitionBuilder;
    ResolvedType? customRouteBuilder;
    if (autoRouter.instanceOf(TypeChecker.fromRuntime(CupertinoAutoRouter))) {
      routeType = RouteType.cupertino;
    } else if (autoRouter
        .instanceOf(TypeChecker.fromRuntime(AdaptiveAutoRouter))) {
      routeType = RouteType.adaptive;
    } else if (autoRouter
        .instanceOf(TypeChecker.fromRuntime(CustomAutoRouter))) {
      routeType = RouteType.custom;

      durationInMilliseconds =
          autoRouter.peek('durationInMilliseconds')?.intValue;
      reverseDurationInMilliseconds =
          autoRouter.peek('reverseDurationInMilliseconds')?.intValue;
      customRouteOpaque = autoRouter.peek('opaque')?.boolValue;
      customRouteBarrierDismissible =
          autoRouter.peek('barrierDismissible')?.boolValue;
      final function =
          autoRouter.peek('transitionsBuilder')?.objectValue.toFunctionValue();
      if (function != null) {
        transitionBuilder = _typeResolver.resolveFunctionType(function);
      }
      final customRouteBuilderValue =
          autoRouter.peek('customRouteBuilder')?.objectValue.toFunctionValue();
      if (customRouteBuilderValue != null) {
        customRouteBuilder =
            _typeResolver.resolveFunctionType(customRouteBuilderValue);
      }
    }

    final deferredLoading =
        autoRouter.peek('deferredLoading')?.boolValue ?? false;

    _globalRouteConfig = RouteConfig(
      routeType: routeType,
      fullscreenDialog: false,
      reverseDurationInMilliseconds: reverseDurationInMilliseconds,
      durationInMilliseconds: durationInMilliseconds,
      customRouteOpaque: customRouteOpaque,
      customRouteBarrierDismissible: customRouteBarrierDismissible,
      transitionBuilder: transitionBuilder,
      customRouteBuilder: customRouteBuilder,
      className: '',
      pathName: '',
      deferredLoading: deferredLoading,
    );

    var replaceInRouteName = autoRouter.peek('replaceInRouteName')?.stringValue;
    final generateRouteArguments =
        autoRouter.peek('generateRouteArguments')?.boolValue;

    final autoRoutes = autoRouter.read('routes').listValue;

    var routerConfig = RouterConfig(
      parentRouteConfig: _globalRouteConfig,
      routerClassName: usesPartBuilder
          ? '_\$${clazz.displayName}'
          : clazz.displayName.substring(1),
      element: clazz,
      replaceInRouteName: replaceInRouteName,
      routes: const [],
      deferredLoading: deferredLoading,
      generateRouteArguments: generateRouteArguments ?? true,
    );

    var routes = _resolveRoutes(routerConfig, autoRoutes);

    return routerConfig.copyWith(routes: routes);
  }

  List<RouteConfig> _resolveRoutes(
    RouterConfig routerConfig,
    List<DartObject> routesList, {
    List<PathParamConfig> inheritedPathParams = const [],
  }) {
    var routeResolver = RouteConfigResolver(routerConfig, _typeResolver);
    final routes = <RouteConfig>[];
    for (var entry in routesList) {
      var routeReader = ConstantReader(entry);
      RouteConfig route;
      route = routeResolver.resolve(routeReader, inheritedPathParams);

      var children = routeReader.peek('children')?.listValue;
      if (children?.isNotEmpty == true) {
        var subRouterConfig = routerConfig.copyWith(
          parent: routerConfig,
        );
        var nestedRoutes = _resolveRoutes(
          subRouterConfig,
          children!,
          inheritedPathParams: inheritedPathParams + route.pathParams,
        );
        route = route.copyWith(
            childRouterConfig: subRouterConfig.copyWith(routes: nestedRoutes));
      }
      routes.add(route);
    }

    // to generate auto redirect for initial routes
    final initialPath = routerConfig.parent == null ? '/' : '';
    var initialRoute = routes.firstOrNull((r) => r.initial);
    if (initialRoute != null && !routes.any((r) => r.pathName == initialPath)) {
      routes.insert(
          0,
          RouteConfig(
            pathName: initialPath,
            redirectTo: initialRoute.pathName,
            className: '',
            fullMatch: true,
            routeType: RouteType.redirect,
            deferredLoading: false,
          ));
    }

    return routes;
  }
}
