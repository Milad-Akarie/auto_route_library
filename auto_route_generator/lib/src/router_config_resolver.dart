import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route/auto_route_annotations.dart';
import 'package:auto_route_generator/route_config_resolver.dart';
import 'package:auto_route_generator/utils.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

const TypeChecker guardsChecker = TypeChecker.fromRuntime(GuardedBy);
const TypeChecker autoRouteChecker = TypeChecker.fromRuntime(AutoRoute);
const TypeChecker unknownRouteChecker = TypeChecker.fromRuntime(UnknownRoute);

// extracts route configs from class fields
class RouterConfigResolver {
  final RouteConfig _globConfig;
  final Resolver _resolver;

  RouterConfigResolver(this._globConfig, this._resolver);

  Future<RouteConfig> resolve(ConstantReader autoRoute, [String pathPrefix]) async {
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
        path = '/${toKababCase(routeConfig.className)}';
      }
    }
    print(pathPrefix);
    routeConfig.pathName = '${pathPrefix ?? ''}$path';

    throwIf(
      type.element is! ClassElement,
      '${type.getDisplayString()} is not a class element',
      element: type.element,
    );

    _extractRouteMetaData(routeConfig, autoRoute);

    routeConfig.name = toLowerCamelCase(routeConfig.className);

    routeConfig.hasWrapper = classElement.allSupertypes.map<String>((el) => el.getDisplayString()).contains('AutoRouteWrapper');

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

  void _extractRouteMetaData(RouteConfig routeConfig, ConstantReader autoRoute) {
    routeConfig.fullscreenDialog = autoRoute.peek('fullscreenDialog')?.boolValue;
    routeConfig.maintainState = autoRoute.peek('maintainState')?.boolValue;

    autoRoute.peek('guards')?.listValue?.map((g) => g.toTypeValue())?.forEach((guard) {
      routeConfig.guards.add(RouteGuardConfig(type: guard.getDisplayString(), import: getImport(guard.element)));
    });

    final returnType = autoRoute.objectValue.type.typeArguments.first;
    routeConfig.returnType = returnType.getDisplayString();

    if (routeConfig.returnType != 'dynamic') {
      final import = getImport(returnType.element);
      if (import != null) {
        routeConfig.imports.add(import);
      }
    }

    if (autoRoute.instanceOf(TypeChecker.fromRuntime(AutoRoute))) {
      routeConfig.routeType = _globConfig.routeType;
      if (_globConfig.routeType == RouteType.custom) {
        routeConfig.transitionBuilder = _globConfig.transitionBuilder;
        routeConfig.durationInMilliseconds = _globConfig.durationInMilliseconds;
        routeConfig.customRouteBarrierDismissible = _globConfig.customRouteBarrierDismissible;
        routeConfig.customRouteOpaque = _globConfig.customRouteOpaque;
      }
      return;
    }

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
          import = getImport(function);
        }
        routeConfig.transitionBuilder = CustomTransitionBuilder(functionName, import);
      }
    } else {
      routeConfig.routeType = _globConfig.routeType;
    }
  }

  void _validatePathParams(RouteConfig route, ClassElement element) {
    var reg = RegExp(r'{(.*?)}');
    var pathParams = route.parameters?.where((p) => p.isPathParameter)?.map((e) => e.paramName)?.toSet() ?? {};
    var templateParams = reg.allMatches(route.pathName).map((e) => e.group(1)).toSet();
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
