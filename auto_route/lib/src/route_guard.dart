import 'dart:async';

import 'package:auto_route/auto_route.dart';

import 'auto_router.dart';

abstract class RouteGuard {
  Future<bool> canNavigate(
      AutoRouterState router, String routeName, Object arguments);
}
