import 'package:auto_route_generator/route_config_visitor.dart';

import 'custom_transtion_builder.dart';

/// holds the extracted route configs
/// to be used in [RouterClassGenerator]

enum RouteType { material, cupertino, custom }

class RouteConfig {
  String import;
  String name;
  bool initial;
  bool fullscreenDialog;
  bool customRouteOpaque;
  bool customRouteBarrierDismissible;
  bool maintainState;
  String className;
  List<RouteParameter> parameters;
  CustomTransitionBuilder transitionBuilder;
  int durationInMilliseconds;
  RouteType routeType = RouteType.material;

  String cupertinoNavTitle;

  RouteConfig();
}
