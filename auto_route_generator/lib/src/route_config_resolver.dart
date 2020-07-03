import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route/auto_route_annotations.dart';
import 'package:auto_route_generator/import_resolver.dart';
import 'package:auto_route_generator/route_config_resolver.dart';
import 'package:auto_route_generator/utils.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

const TypeChecker autoRouteChecker = TypeChecker.fromRuntime(AutoRoute);

// extracts route configs from class fields
class RouteConfigResolver {
  final RouterConfig _routerConfig;
  final Resolver _resolver;

  RouteConfigResolver(this._routerConfig, this._resolver);

  Future<RouteConfig> resolve(ConstantReader autoRoute) async {
    final routeConfig = RouteConfig();
    final type = autoRoute.read('page').typeValue;
    final classElement = type.element as ClassElement;
    final import = getImport(classElement);
    if (import != null) {
      routeConfig.imports.add(import);
    }
    routeConfig.className = type.getDisplayString();
    var path = autoRoute.peek('path')?.stringValue;
    if (path == null) {
      if (autoRoute.peek('initial')?.boolValue == true) {
        path = '/';
      } else {
        path =
            '${_routerConfig.routeNamePrefix}${toKababCase(routeConfig.className)}';
      }
    }
    routeConfig.pathName = path;

    throwIf(
      type.element is! ClassElement,
      '${type.getDisplayString()} is not a class element',
      element: type.element,
    );

    await _extractRouteMetaData(routeConfig, autoRoute);

    routeConfig.name = autoRoute.peek('name')?.stringValue ??
        toLowerCamelCase(routeConfig.className);

    routeConfig.hasWrapper = classElement.allSupertypes
        .map<String>((el) => el.getDisplayString())
        .contains('AutoRouteWrapper');

    final constructor = classElement.unnamedConstructor;

    if (constructor != null && constructor.parameters.isNotEmpty) {
      final paramResolver = RouteParameterResolver(_resolver);
      routeConfig.parameters = [];
      for (ParameterElement p in constructor.parameters) {
        routeConfig.parameters.add(await paramResolver.resolve(p));
      }
    }
    // _validatePathParams(routeConfig, classElement);
    return routeConfig;
  }

  Future<void> _extractRouteMetaData(
      RouteConfig routeConfig, ConstantReader autoRoute) async {
    routeConfig.fullscreenDialog =
        autoRoute.peek('fullscreenDialog')?.boolValue;
    routeConfig.maintainState = autoRoute.peek('maintainState')?.boolValue;

    autoRoute
        .peek('guards')
        ?.listValue
        ?.map((g) => g.toTypeValue())
        ?.forEach((guard) {
      routeConfig.guards.add(RouteGuardConfig(
          type: guard.getDisplayString(), import: getImport(guard.element)));
    });

    final returnType = autoRoute.objectValue.type.typeArguments.first;
    routeConfig.returnType = returnType.getDisplayString();

    if (routeConfig.returnType != 'dynamic') {
      routeConfig.imports.addAll(await resolveImports(_resolver, returnType));
    }

    if (autoRoute.instanceOf(TypeChecker.fromRuntime(MaterialRoute))) {
      routeConfig.routeType = RouteType.material;
    } else if (autoRoute.instanceOf(TypeChecker.fromRuntime(CupertinoRoute))) {
      routeConfig.routeType = RouteType.cupertino;
      routeConfig.cupertinoNavTitle = autoRoute.peek('title')?.stringValue;
    } else if (autoRoute.instanceOf(TypeChecker.fromRuntime(AdaptiveRoute))) {
      routeConfig.routeType = RouteType.adaptive;
      routeConfig.cupertinoNavTitle =
          autoRoute.peek('cupertinoPageTitle')?.stringValue;
    } else if (autoRoute.instanceOf(TypeChecker.fromRuntime(CustomRoute))) {
      routeConfig.routeType = RouteType.custom;
      routeConfig.durationInMilliseconds =
          autoRoute.peek('durationInMilliseconds')?.intValue;
      routeConfig.customRouteOpaque = autoRoute.peek('opaque')?.boolValue;
      routeConfig.customRouteBarrierDismissible =
          autoRoute.peek('barrierDismissible')?.boolValue;
      final function =
          autoRoute.peek('transitionsBuilder')?.objectValue?.toFunctionValue();
      if (function != null) {
        final displayName = function.displayName.replaceFirst(RegExp('^_'), '');
        final functionName = (function.isStatic &&
                function.enclosingElement?.displayName != null)
            ? '${function.enclosingElement.displayName}.$displayName'
            : displayName;

        var import;
        if (function.enclosingElement?.name != 'TransitionsBuilders') {
          import = getImport(function);
        }
        routeConfig.transitionBuilder =
            CustomTransitionBuilder(functionName, import);
      }
    } else {
      var globConfig = _routerConfig.globalRouteConfig;
      routeConfig.routeType = globConfig.routeType;
      if (globConfig.routeType == RouteType.custom) {
        routeConfig.transitionBuilder = globConfig.transitionBuilder;
        routeConfig.durationInMilliseconds = globConfig.durationInMilliseconds;
        routeConfig.customRouteBarrierDismissible =
            globConfig.customRouteBarrierDismissible;
        routeConfig.customRouteOpaque = globConfig.customRouteOpaque;
      }
    }
  }

  void _validatePathParams(RouteConfig route, ClassElement element) {
    var reg = RegExp(r'{(.*?)}');
    var pathParams = route.parameters
            ?.where((p) => p.isPathParam)
            ?.map((e) => e.paramName)
            ?.toSet() ??
        {};
    var templateParams =
        reg.allMatches(route.pathName).map((e) => e.group(1)).toSet();
    throwIf(
      (!templateParams.containsAll(pathParams)),
      "Path ${route.pathName} does not define all path-parameters defined in "
      "${element.displayName} ${pathParams.map((e) => '{$e}').toList()}",
      element: element,
    );

//    if (reg.hasMatch(route.pathName)) {
//      var templateParams = reg.allMatches(route.pathName).map((e) => e.group(1));
//      templateParams.forEach((param) {
//        throwIf(
//          !pathParams.contains(param),
//          "${element.displayName} does not have a path-parameter named {$param}",
//          element: element,
//          todo: 'annotated your path-parameters with @PathParameter()',
//        );
//      });
//    } else {
//      throwIf(
//        pathParams.isNotEmpty,
//        "Path ${route.pathName} does not contain all path-parameters defined in "
//        "${element.displayName} ${pathParams.map((e) => '{$e}').toList()}",
//        element: element,
//      );
//    }
  }
}
