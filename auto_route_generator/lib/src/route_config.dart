import 'package:auto_route_generator/route_config_resolver.dart';
import 'package:auto_route_generator/utils.dart';

import 'custom_transtion_builder.dart';

/// holds the extracted route configs
/// to be used in [RouterClassGenerator]

class RouteConfig {
  List<String> imports = [];
  String name;
  String pathName;
  bool initial;
  bool fullscreenDialog;
  bool customRouteOpaque;
  bool customRouteBarrierDismissible;
  bool maintainState;
  String className;
  String returnType;
  List<RouteParamConfig> parameters;
  CustomTransitionBuilder transitionBuilder;
  int durationInMilliseconds;
  int routeType = RouteType.material;
  List<RouteGuardConfig> guards = [];
  String cupertinoNavTitle;
  bool hasWrapper;
  bool isUnknownRoute;
  RouteConfig();

  String get argumentsHolderClassName {
    return '${className}Arguments';
  }

  @override
  String toString() {
    return 'RouteConfig{imports: $imports, name: $name, pathName: $pathName, initial: $initial, fullscreenDialog: $fullscreenDialog, customRouteOpaque: $customRouteOpaque, customRouteBarrierDismissible: $customRouteBarrierDismissible, maintainState: $maintainState, className: $className, returnType: $returnType, parameters: $parameters, transitionBuilder: $transitionBuilder, durationInMilliseconds: $durationInMilliseconds, routeType: $routeType, guards: $guards, cupertinoNavTitle: $cupertinoNavTitle, hasWrapper: $hasWrapper, isUnknownRoute: $isUnknownRoute}';
  }


}

class RouteType {
  static const int material = 0;
  static const int cupertino = 1;
  static const int adaptive = 2;
  static const int custom = 3;
}
