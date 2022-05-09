import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:auto_route/annotations.dart';
import 'package:source_gen/source_gen.dart';

import '../../utils.dart';
import '../models/importable_type.dart';
import '../models/route_config.dart';
import '../models/route_parameter_config.dart';
import '../models/router_config.dart';
import '../resolvers/route_parameter_resolver.dart';
import '../resolvers/type_resolver.dart';

const TypeChecker autoRouteChecker = TypeChecker.fromUrl(
  'package:auto_route/src/common/auto_route_annotations.dart#AutoRouterAnnotation',
);

const validMetaValues = [
  'String',
  'bool',
  'int',
  'double',
];

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

      return RouteConfig(
        pathName: path!,
        redirectTo: redirectTo,
        className: '',
        fullMatch: autoRoute.peek('fullMatch')?.boolValue ?? true,
        routeType: RouteType.redirect,
      );
    }

    throwIf(
      page.element is! ClassElement,
      '${page.getDisplayString(withNullability: false)} is not a class element',
      element: page.element,
    );

    final classElement = page.element as ClassElement;
    final hasWrappedRoute = classElement.allSupertypes.any((e) =>
        e.getDisplayString(withNullability: false) == 'AutoRouteWrapper');
    var pageType = _typeResolver.resolveType(page);
    var className = page.getDisplayString(withNullability: false);

    if (path == null) {
      var prefix = _routerConfig.parent != null ? '' : '/';
      if (autoRoute.peek('initial')?.boolValue == true) {
        path = prefix;
      } else {
        path = '$prefix${toKababCase(className)}';
      }
    }
    throwIf(
      path.startsWith("/") && _routerConfig.parent != null,
      'Child [$path] can not start with a forward slash',
    );

    var pathName = path;
    var pathParams = RouteParameterResolver.extractPathParams(path);

    var fullscreenDialog = autoRoute.peek('fullscreenDialog')?.boolValue;
    var maintainState = autoRoute.peek('maintainState')?.boolValue;
    var fullMatch = autoRoute.peek('fullMatch')?.boolValue;
    var initial = autoRoute.peek('initial')?.boolValue ?? false;
    var usesPathAsKey = autoRoute.peek('usesPathAsKey')?.boolValue ?? false;

    var guards = <ResolvedType>[];
    autoRoute
        .peek('guards')
        ?.listValue
        .map((g) => g.toTypeValue())
        .forEach((guard) {
      guards.add(_typeResolver.resolveType(guard!));
    });

    var returnType = ResolvedType(name: 'dynamic');
    var dartType = autoRoute.objectValue.type;
    if (dartType is InterfaceType) {
      returnType = _typeResolver.resolveType(dartType.typeArguments.first);
    }

    int routeType = RouteType.material;
    String? cupertinoNavTitle;
    int? durationInMilliseconds;
    int? reverseDurationInMilliseconds;
    bool? customRouteOpaque;
    bool? customRouteBarrierDismissible;
    String? customRouteBarrierLabel;
    ResolvedType? customRouteBuilder;
    ResolvedType? transitionBuilder;
    int? customRouteBarrierColor;
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
          autoRoute.peek('transitionsBuilder')?.objectValue.toFunctionValue();
      if (function != null) {
        transitionBuilder = _typeResolver.resolveFunctionType(function);
      }
      final builderFunction =
          autoRoute.peek('customRouteBuilder')?.objectValue.toFunctionValue();
      if (builderFunction != null) {
        customRouteBuilder = _typeResolver.resolveFunctionType(builderFunction);
      }
      customRouteBarrierColor = autoRoute.peek('barrierColor')?.intValue;
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

    final meta = <MetaEntry>[];
    for (final entry in autoRoute
        .read('meta')
        .mapValue
        .entries
        .where((e) => e.value?.type != null)) {
      final valueType =
          entry.value!.type!.getDisplayString(withNullability: false);
      throwIf(!validMetaValues.contains(valueType),
          'Meta value type ${valueType} is not supported!\nSupported types are ${validMetaValues}');
      switch (valueType) {
        case 'bool':
          {
            meta.add(MetaEntry<bool>(
              key: entry.key!.toStringValue()!,
              type: valueType,
              value: entry.value!.toBoolValue()!,
            ));
            break;
          }
        case 'String':
          {
            meta.add(MetaEntry<String>(
              key: entry.key!.toStringValue()!,
              type: valueType,
              value: entry.value!.toStringValue()!,
            ));

            break;
          }
        case 'int':
          {
            meta.add(MetaEntry<int>(
              key: entry.key!.toStringValue()!,
              type: valueType,
              value: entry.value!.toIntValue()!,
            ));
            break;
          }
        case 'double':
          {
            meta.add(MetaEntry<double>(
              key: entry.key!.toStringValue()!,
              type: valueType,
              value: entry.value!.toDoubleValue()!,
            ));
            break;
          }
      }
    }

    var name = autoRoute.peek('name')?.stringValue;
    var replacementInRouteName = _routerConfig.replaceInRouteName;

    final constructor = classElement.unnamedConstructor;
    throwIf(
      constructor == null,
      'Route widgets must have an unnamed constructor',
    );
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

    var pathParameters = parameters.where((element) => element.isPathParam);

    if (parameters.any((p) => p.isPathParam || p.isQueryParam)) {
      var unParsableRequiredArgs = parameters.where((p) =>
          (p.isRequired || p.isPositional) &&
          !p.isPathParam &&
          !p.isQueryParam);
      if (unParsableRequiredArgs.isNotEmpty) {
        print(
            '\nWARNING => Because [$className] has required parameters ${unParsableRequiredArgs.map((e) => e.paramName)} '
            'that can not be parsed from path,\n@PathParam() and @QueryParam() annotations will be ignored.\n');
      }
    }

    if (pathParameters.isNotEmpty) {
      for (var pParam in pathParameters) {
        throwIf(!validPathParamTypes.contains(pParam.type.name),
            "Parameter [${pParam.name}] must be of a type that can be parsed from a [String] because it will also obtain it's value from a path\nvalid types: $validPathParamTypes",
            element: pParam.element);
      }
    }

    return RouteConfig(
      className: className,
      name: name,
      initial: initial,
      pathParams: pathParams,
      routeType: routeType,
      hasWrappedRoute: hasWrappedRoute,
      transitionBuilder: transitionBuilder,
      customRouteBuilder: customRouteBuilder,
      customRouteBarrierDismissible: customRouteBarrierDismissible,
      customRouteOpaque: customRouteOpaque,
      cupertinoNavTitle: cupertinoNavTitle,
      fullscreenDialog: fullscreenDialog,
      maintainState: maintainState,
      parameters: parameters,
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
      usesPathAsKey: usesPathAsKey,
      meta: meta,
      customRouteBarrierColor: customRouteBarrierColor,
    );
  }
}
