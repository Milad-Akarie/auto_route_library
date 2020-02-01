import 'package:auto_route_generator/route_config_visitor.dart';
import 'package:auto_route_generator/src/route_guard.dart';

import 'custom_transtion_builder.dart';

/// holds the extracted route configs
/// to be used in [RouterClassGenerator]

enum RouteType { material, cupertino, custom }

class RouteConfig {
  String import;
  String name;
  String pathName;
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
  List<Guard> guards = [];

  String cupertinoNavTitle;

  bool hasWrapper;

  RouteConfig();

  @override
  String toString() {
    return 'RouteConfig{import: $import, name: $name, initial: $initial, fullscreenDialog: $fullscreenDialog, customRouteOpaque: $customRouteOpaque, customRouteBarrierDismissible: $customRouteBarrierDismissible, maintainState: $maintainState, className: $className, parameters: $parameters, transitionBuilder: $transitionBuilder, durationInMilliseconds: $durationInMilliseconds, routeType: $routeType, cupertinoNavTitle: $cupertinoNavTitle, hasWrapper: $hasWrapper}';
  }
}
