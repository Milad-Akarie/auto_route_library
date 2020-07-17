import 'dart:async';

import 'package:auto_route/src/extended_navigator.dart';

abstract class RouteGuard {
  Future<bool> canNavigate(
    ExtendedNavigatorState navigator,
    String routeName,
    Object arguments,
  );
}
