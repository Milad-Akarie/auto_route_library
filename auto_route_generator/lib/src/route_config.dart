import 'package:auto_route_generator/route_config_resolver.dart';

import 'custom_transition_builder.dart';

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
  int reverseDurationInMilliseconds;
  int routeType = RouteType.material;
  List<RouteGuardConfig> guards = [];
  String cupertinoNavTitle;
  bool hasWrapper;
  RouterConfig routerConfig;

  bool hasConstConstructor;

  RouteConfig();

  String get argumentsHolderClassName {
    return '${className}Arguments';
  }

  String get templateName {
    return pathName.contains(":") ? '_$name' : name;
  }

  List<RouteParamConfig> get argParams {
    return parameters
            ?.where((p) => !p.isPathParam && !p.isQueryParam)
            ?.toList() ??
        [];
  }
}

class RouteType {
  static const int material = 0;
  static const int cupertino = 1;
  static const int adaptive = 2;
  static const int custom = 3;
}
