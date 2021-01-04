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

    final page = autoRoute.peek('page')?.typeValue;
    var path = autoRoute.peek('path')?.stringValue;
    if (page == null) {
      var redirectTo = autoRoute.peek('redirectTo')?.stringValue;
      throwIf(redirectTo == null,
          'Route must have either a page or a redirect destination');
      return config
        ..pathName = path
        ..redirectTo = redirectTo
        ..fullMatch = autoRoute.peek('fullMatch')?.boolValue
        ..routeType = RouteType.redirect;
    }

    final classElement = page.element as ClassElement;
    config.pageType = _typeResolver.resolveType(page);
    config.className = page.getDisplayString(withNullability: false);

    if (path == null) {
      var prefix = _routerConfig.parent != null ? '' : '/';
      if (autoRoute.peek('initial')?.boolValue == true) {
        path = prefix;
      } else {
        if (_routerConfig.usesLegacyGenerator) {
          path =
              '${_routerConfig.routeNamePrefix}${toKababCase(config.className)}';
        } else {
          path = '$prefix${toKababCase(config.className)}';
        }
      }
    } else if (!_routerConfig.usesLegacyGenerator) {
      throwIf(
        path.startsWith("/") && _routerConfig.parent != null,
        'Child [$path] can not start with a forward slash',
      );
    }

    config.pathName = path;
    config.pathParams = RouteParameterResolver.extractPathParams(path);

    throwIf(
      page.element is! ClassElement,
      '${page.getDisplayString(withNullability: false)} is not a class element',
      element: page.element,
    );

    _extractRouteMetaDataInto(config, autoRoute);

    config.name = autoRoute.peek('name')?.stringValue;
    config.replacementInRouteName = _routerConfig.replaceInRouteName;

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

    ClassElement pageClass = page.element;
    if (config.pathParams?.isNotEmpty == true) {
      var pathParamCandidates = config.parameters
              ?.where((p) => p.isPathParam)
              ?.map((e) => e.paramName) ??
          [];
      for (var pParam in config.pathParams) {
        throwIf(!pathParamCandidates.contains(pParam.name),
            '${config.className} does not have a constructor parameter (annotated with @PathParam()) with an alias/name [${pParam.name}]',
            element: pageClass.unnamedConstructor);
        var param =
            config.parameters.firstWhere((e) => e.paramName == pParam.name);
        throwIf(!validPathParamTypes.contains(param.type.name),
            "Parameter [${pParam.name}] must be of a type that can be parsed from a [String] because it will also obtain it's value from a path\nvalid types: $validPathParamTypes",
            element: param.element);
      }
    }
    return config;
  }

  void _extractRouteMetaDataInto(RouteConfig config, ConstantReader autoRoute) {
    config.fullscreenDialog = autoRoute.peek('fullscreenDialog')?.boolValue;
    config.maintainState = autoRoute.peek('maintainState')?.boolValue;
    config.fullMatch = autoRoute.peek('fullMatch')?.boolValue;
    config.usesTabsRouter = autoRoute.peek('usesTabsRouter')?.boolValue;

    autoRoute
        .peek('guards')
        ?.listValue
        ?.map((g) => g.toTypeValue())
        ?.forEach((guard) {
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
      config.cupertinoNavTitle =
          autoRoute.peek('cupertinoPageTitle')?.stringValue;
    } else if (autoRoute.instanceOf(TypeChecker.fromRuntime(CustomRoute))) {
      config.routeType = RouteType.custom;

      config.durationInMilliseconds =
          autoRoute.peek('durationInMilliseconds')?.intValue;
      config.reverseDurationInMilliseconds =
          autoRoute.peek('reverseDurationInMilliseconds')?.intValue;
      config.customRouteOpaque = autoRoute.peek('opaque')?.boolValue;
      config.customRouteBarrierDismissible =
          autoRoute.peek('barrierDismissible')?.boolValue;
      config.customRouteBarrierLabel =
          autoRoute.peek('barrierLabel')?.stringValue;

      final function =
          autoRoute.peek('transitionsBuilder')?.objectValue?.toFunctionValue();
      if (function != null) {
        config.transitionBuilder =
            _typeResolver.resolveImportableFunctionType(function);
      }
      final builderFunction =
          autoRoute.peek('customRouteBuilder')?.objectValue?.toFunctionValue();
      if (builderFunction != null) {
        config.customRouteBuilder =
            _typeResolver.resolveImportableFunctionType(builderFunction);
      }
    } else {
      var globConfig = _routerConfig.globalRouteConfig;
      config.routeType = globConfig.routeType;
      if (globConfig.routeType == RouteType.custom) {
        config.transitionBuilder = globConfig.transitionBuilder;
        config.durationInMilliseconds = globConfig.durationInMilliseconds;
        config.customRouteBarrierDismissible =
            globConfig.customRouteBarrierDismissible;
        config.customRouteOpaque = globConfig.customRouteOpaque;
        config.reverseDurationInMilliseconds =
            globConfig.reverseDurationInMilliseconds;
        config.customRouteBuilder = globConfig.customRouteBuilder;
      }
    }
  }
}
