import 'package:auto_route_generator/route_config_resolver.dart';

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
}

class RouteType {
  static const int material = 0;
  static const int cupertino = 1;
  static const int custom = 2;
}
