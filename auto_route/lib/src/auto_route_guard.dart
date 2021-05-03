import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/router/controller/routing_controller.dart';

abstract class AutoRouteGuard {
  Future<bool> canNavigate(
    RouteMatch route,
    StackRouter router,
  );
}
