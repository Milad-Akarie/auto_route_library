import 'package:flutter/widgets.dart' show BuildContext;

import '../route/route_data.dart';
import 'controller/routing_controller.dart';
import 'widgets/auto_router.dart';

extension AutoRouterX on BuildContext {
  RoutingController get router => AutoRouter.of(this);

  RoutingController findChildRouter(String routeKey) =>
      AutoRouter.ofChildRoute(this, routeKey);

  RouteData get route => RouteData.of(this);
}
