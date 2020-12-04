import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route/annotations.dart';
import 'package:auto_route_generator/import_resolver.dart';
import 'package:auto_route_generator/route_config_resolver.dart';
import 'package:auto_route_generator/utils.dart';
import 'package:source_gen/source_gen.dart';

const TypeChecker autoRouteChecker = TypeChecker.fromRuntime(AutoRoute);

// extracts route configs from class fields
class RouteConfigResolver {
  final RouterConfig _routerConfig;
  final TypeResolver _typeResolver;

  RouteConfigResolver(this._routerConfig, this._typeResolver);

  Future<RouteConfig> resolve(ConstantReader autoRoute) async {
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
        if (_routerConfig.usesLegacyNavigator) {
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

    await _extractRouteMetaData(config, autoRoute);

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
          config.parameters.add(await paramResolver.resolve(p));
        }
      }
    }
    // _validatePathParams(routeConfig, classElement);
    return config;
  }

  Future<void> _extractRouteMetaData(RouteConfig routeConfig, ConstantReader autoRoute) async {
    routeConfig.fullscreenDialog = autoRoute.peek('fullscreenDialog')?.boolValue;
    routeConfig.maintainState = autoRoute.peek('maintainState')?.boolValue;

    autoRoute.peek('guards')?.listValue?.map((g) => g.toTypeValue())?.forEach((guard) {
      routeConfig.guards.add(_typeResolver.resolveType(guard));
    });

    final returnType = autoRoute.objectValue.type.typeArguments.first;
    routeConfig.returnType = _typeResolver.resolveType(returnType);

    if (autoRoute.instanceOf(TypeChecker.fromRuntime(MaterialRoute))) {
      routeConfig.routeType = RouteType.material;
    } else if (autoRoute.instanceOf(TypeChecker.fromRuntime(CupertinoRoute))) {
      routeConfig.routeType = RouteType.cupertino;
      routeConfig.cupertinoNavTitle = autoRoute.peek('title')?.stringValue;
    } else if (autoRoute.instanceOf(TypeChecker.fromRuntime(AdaptiveRoute))) {
      routeConfig.routeType = RouteType.adaptive;
      routeConfig.cupertinoNavTitle = autoRoute.peek('cupertinoPageTitle')?.stringValue;
    } else if (autoRoute.instanceOf(TypeChecker.fromRuntime(CustomRoute))) {
      routeConfig.routeType = RouteType.custom;
      routeConfig.durationInMilliseconds = autoRoute.peek('durationInMilliseconds')?.intValue;
      routeConfig.customRouteOpaque = autoRoute.peek('opaque')?.boolValue;
      routeConfig.customRouteBarrierDismissible = autoRoute.peek('barrierDismissible')?.boolValue;
      final function = autoRoute.peek('transitionsBuilder')?.objectValue?.toFunctionValue();
      if (function != null) {
        final displayName = function.displayName.replaceFirst(RegExp('^_'), '');
        final functionName = (function.isStatic && function.enclosingElement?.displayName != null)
            ? '${function.enclosingElement.displayName}.$displayName'
            : displayName;

        var import;
        if (function.enclosingElement?.name != 'TransitionsBuilders') {
          import = _typeResolver.resolveImport(function);
        }
        routeConfig.transitionBuilder = ImportableType(
          name: functionName,
          import: import,
        );
      }
    } else {
      var globConfig = _routerConfig.globalRouteConfig;
      routeConfig.routeType = globConfig.routeType;
      if (globConfig.routeType == RouteType.custom) {
        routeConfig.transitionBuilder = globConfig.transitionBuilder;
        routeConfig.durationInMilliseconds = globConfig.durationInMilliseconds;
        routeConfig.customRouteBarrierDismissible = globConfig.customRouteBarrierDismissible;
        routeConfig.customRouteOpaque = globConfig.customRouteOpaque;
      }
    }
  }
}
