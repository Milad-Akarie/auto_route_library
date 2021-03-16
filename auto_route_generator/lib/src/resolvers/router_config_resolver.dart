import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route/annotations.dart';
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

  RouterConfig resolve(ConstantReader autoRouter, ClassElement clazz) {
    /// ensure router config classes are prefixed with $
    /// to use the stripped name for the generated class
    throwIf(
      !clazz.displayName.startsWith(r'$'),
      'Router class name must be prefixed with \$',
      element: clazz,
    );

    int routeType = RouteType.material;
    int? durationInMilliseconds;
    bool? customRouteOpaque;
    bool? customRouteBarrierDismissible;
    ImportableType? transitionBuilder;
    ImportableType? customRouteBuilder;

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
      customRouteOpaque = autoRouter.peek('opaque')?.boolValue;
      customRouteBarrierDismissible =
          autoRouter.peek('barrierDismissible')?.boolValue;
      final function =
          autoRouter.peek('transitionsBuilder')?.objectValue?.toFunctionValue();
      if (function != null) {
        transitionBuilder =
            _typeResolver.resolveImportableFunctionType(function);
      }
      final customRouteBuilderValue =
          autoRouter.peek('customRouteBuilder')?.objectValue?.toFunctionValue();
      if (customRouteBuilderValue != null) {
        customRouteBuilder = _typeResolver
            .resolveImportableFunctionType(customRouteBuilderValue);
      }
    }

    _globalRouteConfig = RouteConfig(
      routeType: routeType,
      fullscreenDialog: false,
      reverseDurationInMilliseconds: null,
      durationInMilliseconds: durationInMilliseconds,
      customRouteOpaque: customRouteOpaque,
      customRouteBarrierDismissible: customRouteBarrierDismissible,
      transitionBuilder: transitionBuilder,
      customRouteBuilder: customRouteBuilder,
      className: '',
      pathName: '',
    );

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
      globalRouteConfig: _globalRouteConfig,
      routerClassName: clazz.displayName.substring(1),
      element: clazz,
      routesClassName: routesClassName,
      routeNamePrefix: routeNamePrefix,
      generateNavigationHelper: generateNavigationExt,
      usesLegacyGenerator: usesLegacyGenerator,
      replaceInRouteName: replaceInRouteName,
      routes: const [],
    );

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
      var children = routeReader.peek('children')?.listValue;
      if (children?.isNotEmpty == true) {
        var name = capitalize(valueOr(route.name, route.className));
        var subRouterConfig = routerConfig.copyWith(
          routerClassName: '${name}Router',
          routesClassName: '${name}Routes',
          parent: routerConfig,
        );
        var nestedRoutes = _resolveRoutes(subRouterConfig, children!);
        route = route.copyWith(
            childRouterConfig: subRouterConfig.copyWith(routes: nestedRoutes));
      }
      routes.add(route);
    }
    return routes;
  }
}
