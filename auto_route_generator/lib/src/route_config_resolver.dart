import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route/annotations.dart';
import 'package:auto_route_generator/import_resolver.dart';
import 'package:auto_route_generator/route_config_resolver.dart';
import 'package:auto_route_generator/utils.dart';
import 'package:source_gen/source_gen.dart';

const TypeChecker autoRouteChecker = TypeChecker.fromRuntime(AutoRoute);

// extracts route configs from class fields and their meta data
class RouteConfigResolver {
  final RouterConfig _routerConfig;
  final TypeResolver _typeResolver;

  RouteConfigResolver(this._routerConfig, this._typeResolver);

  RouteConfig resolve(ConstantReader autoRoute) {
    final config = RouteConfig();
    final type = autoRoute.read('page').typeValue;
    final classElement = type.element as ClassElement;

    config.pageType = _typeResolver.resolveType(type);

    config.className = type.getDisplayString(withNullability: false);
    var path = autoRoute.peek('path')?.stringValue;
    if (path == null) {
      if (autoRoute.peek('initial')?.boolValue == true) {
        path = '/';
      } else {
        if (_routerConfig.usesLegacyGenerator) {
          path = '${_routerConfig.routeNamePrefix}${toKababCase(config.className)}';
        } else {
          path = '${toKababCase(config.className)}';
        }
      }
    }

    config.pathName = path;
    config.pathParams = RouteParameterResolver.extractPathParams(path);

    throwIf(
      type.element is! ClassElement,
      '${type.getDisplayString(withNullability: false)} is not a class element',
      element: type.element,
    );

    _extractRouteMetaDataInto(config, autoRoute);

    config.name = autoRoute.peek('name')?.stringValue;

    config.hasWrapper = classElement.allSupertypes
        .map<String>((el) => el.getDisplayString(withNullability: false))
        .contains('AutoRouteWrapper');

    final constructor = classElement.unnamedConstructor;

    var params = constructor?.parameters;
    if (params?.isNotEmpty == true) {
      if (constructor.isConst &&
          params.length == 1 &&
          params.first.type.getDisplayString(withNullability: false) == 'Key') {
        config.hasConstConstructor = true;
      } else {
        final paramResolver = RouteParameterResolver(_typeResolver);
        config.parameters = [];

        for (ParameterElement p in constructor.parameters) {
          config.parameters.add(paramResolver.resolve(p));
        }
      }
    }
    // _validatePathParams(routeConfig, classElement);
    return config;
  }

  void _extractRouteMetaDataInto(RouteConfig config, ConstantReader autoRoute) {
    config.fullscreenDialog = autoRoute.peek('fullscreenDialog')?.boolValue;
    config.maintainState = autoRoute.peek('maintainState')?.boolValue;

    autoRoute.peek('guards')?.listValue?.map((g) => g.toTypeValue())?.forEach((guard) {
      config.guards.add(_typeResolver.resolveType(guard));
    });

    final returnType = autoRoute.objectValue.type.typeArguments.first;
    config.returnType = _typeResolver.resolveType(returnType);

    if (autoRoute.instanceOf(TypeChecker.fromRuntime(MaterialRoute))) {
      config.routeType = RouteType.material;
    } else if (autoRoute.instanceOf(TypeChecker.fromRuntime(CupertinoRoute))) {
      config.routeType = RouteType.cupertino;
      config.cupertinoNavTitle = autoRoute.peek('title')?.stringValue;
    } else if (autoRoute.instanceOf(TypeChecker.fromRuntime(AdaptiveRoute))) {
      config.routeType = RouteType.adaptive;
      config.cupertinoNavTitle = autoRoute.peek('cupertinoPageTitle')?.stringValue;
    } else if (autoRoute.instanceOf(TypeChecker.fromRuntime(CustomRoute))) {
      config.routeType = RouteType.custom;

      config.durationInMilliseconds = autoRoute.peek('durationInMilliseconds')?.intValue;
      config.reverseDurationInMilliseconds = autoRoute.peek('reverseDurationInMilliseconds')?.intValue;
      config.customRouteOpaque = autoRoute.peek('opaque')?.boolValue;
      config.customRouteBarrierDismissible = autoRoute.peek('barrierDismissible')?.boolValue;
      config.customRouteBarrierLabel = autoRoute.peek('barrierLabel')?.stringValue;

      final function = autoRoute.peek('transitionsBuilder')?.objectValue?.toFunctionValue();
      if (function != null) {
        config.transitionBuilder = _typeResolver.resolveImportableFunctionType(function);
      }
      final builderFunction = autoRoute.peek('customRouteBuilder')?.objectValue?.toFunctionValue();
      if (builderFunction != null) {
        config.customRouteBuilder = _typeResolver.resolveImportableFunctionType(builderFunction);
      }
    } else {
      var globConfig = _routerConfig.globalRouteConfig;
      config.routeType = globConfig.routeType;
      if (globConfig.routeType == RouteType.custom) {
        config.transitionBuilder = globConfig.transitionBuilder;
        config.durationInMilliseconds = globConfig.durationInMilliseconds;
        config.customRouteBarrierDismissible = globConfig.customRouteBarrierDismissible;
        config.customRouteOpaque = globConfig.customRouteOpaque;
        config.reverseDurationInMilliseconds = globConfig.reverseDurationInMilliseconds;
        config.customRouteBuilder = globConfig.customRouteBuilder;
      }
    }
  }
}
