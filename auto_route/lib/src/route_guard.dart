import 'dart:async';

import 'package:auto_route/auto_route.dart';

abstract class RouteGuard {
  Future<bool> canNavigate(
      ExtendedNavigatorState navigator, String routeName, Object arguments);
}
