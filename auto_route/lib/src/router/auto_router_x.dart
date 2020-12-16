import 'package:flutter/widgets.dart' show BuildContext;

import '../route/route_data.dart';
import 'controller/routing_controller.dart';
import 'widgets/auto_router.dart';

extension AutoRouterX on BuildContext {
  StackController get router => AutoRouter.of(this);

  RoutingController childRouterOf(String routeKey) => AutoRouter.childRouterOf(this, routeKey);

  RouteData get route => RouteData.of(this);
}
