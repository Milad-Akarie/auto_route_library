import 'package:auto_route/src/router/controller/routing_controller.dart';

import 'route/page_route_info.dart';

abstract class AutoRouteGuard {
  Future<bool> canNavigate(
    List<PageRouteInfo> pendingRoutes,
    StackRouter router,
  );
}
