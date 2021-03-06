import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route/annotations.dart';
import 'package:source_gen/source_gen.dart';

import '../../utils.dart';
import '../models/importable_type.dart';
import '../models/route_config.dart';
import '../models/route_parameter_config.dart';
import '../models/router_config.dart';
import '../resolvers/route_parameter_resolver.dart';
import '../resolvers/type_resolver.dart';

const TypeChecker autoRouteChecker = TypeChecker.fromRuntime(AutoRoute);

// extracts route configs from class fields and their meta data
class RouteConfigResolver {
  final RouterConfig _routerConfig;
  final TypeResolver _typeResolver;

  RouteConfigResolver(this._routerConfig, this._typeResolver);

  RouteConfig resolve(ConstantReader autoRoute) {
    final page = autoRoute.peek('page')?.typeValue;
    var path = autoRoute.peek('path')?.stringValue;
    if (page == null) {
      var redirectTo = autoRoute.peek('redirectTo')?.stringValue;
      throwIf(
        redirectTo == null,
        'Route must have either a page or a redirect destination',
      );
      throwIf(
        _routerConfig.usesLegacyGenerator,
        'Redirect routes are not supported in legacy mode.',
        element: _routerConfig.element,
      );
      return RouteConfig(
        pathName: path!,
        redirectTo: redirectTo,
        className: '',
        fullMatch: autoRoute.peek('fullMatch')?.boolValue ?? true,
        routeType: RouteType.redirect,
      );
    }
    final classElement = page.element as ClassElement;
    var pageType = _typeResolver.resolveType(page);
    var className = page.getDisplayString(withNullability: false);

    if (path == null) {
      var prefix = _routerConfig.parent != null ? '' : '/';
      if (autoRoute.peek('initial')?.boolValue == true) {
        path = prefix;
      } else {
        if (_routerConfig.usesLegacyGenerator) {
          path = '${_routerConfig.routeNamePrefix}${toKababCase(className)}';
        } else {
          path = '$prefix${toKababCase(className)}';
        }
      }
    } else if (!_routerConfig.usesLegacyGenerator) {
      throwIf(
        path.startsWith("/") && _routerConfig.parent != null,
        'Child [$path] can not start with a forward slash',
      );
    }

    var pathName = path;
    var pathParams = RouteParameterResolver.extractPathParams(path);

    throwIf(
      page.element is! ClassElement,
      '${page.getDisplayString(withNullability: false)} is not a class element',
      element: page.element,
    );

    var fullscreenDialog = autoRoute.peek('fullscreenDialog')?.boolValue;
    var maintainState = autoRoute.peek('maintainState')?.boolValue;
    var fullMatch = autoRoute.peek('fullMatch')?.boolValue;
    var usesTabsRouter = autoRoute.peek('usesTabsRouter')?.boolValue;
    var guards = <ImportableType>[];
    autoRoute
        .peek('guards')
        ?.listValue
        ?.map((g) => g.toTypeValue())
        .forEach((guard) {
      guards.add(_typeResolver.resolveType(guard!));
    });

    var returnType = _typeResolver
        .resolveType(autoRoute.objectValue.type!.typeArguments.first);

    int routeType = RouteType.material;
    String? cupertinoNavTitle;
    int? durationInMilliseconds;
    int? reverseDurationInMilliseconds;
    bool? customRouteOpaque;
    bool? customRouteBarrierDismissible;
    String? customRouteBarrierLabel;
    ImportableType? customRouteBuilder;
    ImportableType? transitionBuilder;
    if (autoRoute.instanceOf(TypeChecker.fromRuntime(MaterialRoute))) {
      routeType = RouteType.material;
    } else if (autoRoute.instanceOf(TypeChecker.fromRuntime(CupertinoRoute))) {
      routeType = RouteType.cupertino;
      cupertinoNavTitle = autoRoute.peek('title')?.stringValue;
    } else if (autoRoute.instanceOf(TypeChecker.fromRuntime(AdaptiveRoute))) {
      routeType = RouteType.adaptive;
      cupertinoNavTitle = autoRoute.peek('cupertinoPageTitle')?.stringValue;
    } else if (autoRoute.instanceOf(TypeChecker.fromRuntime(CustomRoute))) {
      routeType = RouteType.custom;
      durationInMilliseconds =
          autoRoute.peek('durationInMilliseconds')?.intValue;
      reverseDurationInMilliseconds =
          autoRoute.peek('reverseDurationInMilliseconds')?.intValue;
      customRouteOpaque = autoRoute.peek('opaque')?.boolValue;
      customRouteBarrierDismissible =
          autoRoute.peek('barrierDismissible')?.boolValue;
      customRouteBarrierLabel = autoRoute.peek('barrierLabel')?.stringValue;
      final function =
          autoRoute.peek('transitionsBuilder')?.objectValue?.toFunctionValue();
      if (function != null) {
        transitionBuilder =
            _typeResolver.resolveImportableFunctionType(function);
      }
      final builderFunction =
          autoRoute.peek('customRouteBuilder')?.objectValue?.toFunctionValue();
      if (builderFunction != null) {
        customRouteBuilder =
            _typeResolver.resolveImportableFunctionType(builderFunction);
      }
    } else {
      var globConfig = _routerConfig.globalRouteConfig;
      routeType = globConfig.routeType;
      if (globConfig.routeType == RouteType.custom) {
        transitionBuilder = globConfig.transitionBuilder;
        durationInMilliseconds = globConfig.durationInMilliseconds;
        customRouteBarrierDismissible =
            globConfig.customRouteBarrierDismissible;
        customRouteOpaque = globConfig.customRouteOpaque;
        reverseDurationInMilliseconds =
            globConfig.reverseDurationInMilliseconds;
        customRouteBuilder = globConfig.customRouteBuilder;
      }
    }

    var name = autoRoute.peek('name')?.stringValue;
    var replacementInRouteName = _routerConfig.replaceInRouteName;

    var hasWrapper = classElement.allSupertypes
        .map<String>((el) => el.getDisplayString(withNullability: false))
        .contains('AutoRouteWrapper');

    final constructor = classElement.unnamedConstructor;
    var hasConstConstructor = false;
    var params = constructor!.parameters;
    var parameters = <ParamConfig>[];
    if (params.isNotEmpty == true) {
      if (constructor.isConst &&
          params.length == 1 &&
          params.first.type.getDisplayString(withNullability: false) == 'Key') {
        hasConstConstructor = true;
      } else {
        final paramResolver = RouteParameterResolver(_typeResolver);
        for (ParameterElement p in constructor.parameters) {
          parameters.add(paramResolver.resolve(p));
        }
      }
    }

    ClassElement pageClass = page.element as ClassElement;
    if (pathParams.isNotEmpty == true) {
      var pathParamCandidates =
          parameters.where((p) => p.isPathParam).map((e) => e.paramName);
      for (var pParam in pathParams) {
        throwIf(!pathParamCandidates.contains(pParam.name),
            '$className does not have a constructor parameter (annotated with @PathParam()) with an alias/name [${pParam.name}]',
            element: pageClass.unnamedConstructor);
        var param = parameters.firstWhere((e) => e.paramName == pParam.name);
        throwIf(!validPathParamTypes.contains(param.type.name),
            "Parameter [${pParam.name}] must be of a type that can be parsed from a [String] because it will also obtain it's value from a path\nvalid types: $validPathParamTypes",
            element: param.element);
      }
    }

    return RouteConfig(
      className: className,
      name: name,
      pathParams: pathParams,
      usesTabsRouter: usesTabsRouter,
      routeType: routeType,
      transitionBuilder: transitionBuilder,
      customRouteBuilder: customRouteBuilder,
      customRouteBarrierDismissible: customRouteBarrierDismissible,
      customRouteOpaque: customRouteOpaque,
      cupertinoNavTitle: cupertinoNavTitle,
      fullscreenDialog: fullscreenDialog,
      maintainState: maintainState,
      parameters: parameters,
      hasWrapper: hasWrapper,
      hasConstConstructor: hasConstConstructor,
      durationInMilliseconds: durationInMilliseconds,
      reverseDurationInMilliseconds: reverseDurationInMilliseconds,
      replacementInRouteName: replacementInRouteName,
      returnType: returnType,
      pageType: pageType,
      guards: guards,
      customRouteBarrierLabel: customRouteBarrierLabel,
      pathName: pathName,
      fullMatch: fullMatch,
    );
  }
}
