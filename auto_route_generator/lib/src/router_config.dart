import 'package:auto_route/auto_route_annotations.dart';
import 'package:auto_route_generator/route_config_resolver.dart';
import 'package:source_gen/source_gen.dart';

import '../utils.dart';

/// Extracts and holds router configs
/// to be used in [RouterClassGenerator]

class RouterConfig {
  bool generateNavigationHelper;
  bool generateArgsHolderForSingleParameterRoutes;

  final globalRouteConfig = RouteConfig();

  RouterConfig.fromAnnotation(ConstantReader autoRouter) {
    generateNavigationHelper = autoRouter.peek('generateNavigationHelperExtension')?.boolValue ?? false;
    generateArgsHolderForSingleParameterRoutes = autoRouter.peek('generateArgsHolderForSingleParameterRoutes')?.boolValue ?? true;

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
  }
}

class RoutesConfig{
  String routesClassName;
  String routeNamePrefix;
  RoutesConfig.fromAnnotatedElement(AnnotatedElement annotatedElement){
    routesClassName = capitalize(annotatedElement.element.name);
    routeNamePrefix = annotatedElement.annotation.peek('namePrefix')?.stringValue ?? '';
  }
}