import 'package:auto_route_generator/route_config_visitor.dart';
import 'package:auto_route_generator/src/route_guard_config.dart';
import 'package:auto_route_generator/src/route_parameter_config.dart';

import 'custom_transtion_builder.dart';

/// holds the extracted route configs
/// to be used in [RouterClassGenerator]

enum RouteType { material, cupertino, custom }

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
  List<RouteParameterConfig> parameters;
  CustomTransitionBuilder transitionBuilder;
  int durationInMilliseconds;
  RouteType routeType = RouteType.material;
  List<RouteGuardConifg> guards = [];

  String cupertinoNavTitle;

  bool hasWrapper;

  RouteConfig();
}
