import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart' show BuildContext;

import 'controller/routing_controller.dart';
import 'widgets/auto_router.dart';

extension AutoRouterX on BuildContext {
  StackRouter get router => AutoRouter.of(this);

  TabsRouter get tabsRouter => AutoTabsRouter.of(this);

  RoutingController innerRouterOf(String routeKey) =>
      AutoRouter.innerRouterOf(this, routeKey);

  RouteData get route => RouteData.of(this);
}
