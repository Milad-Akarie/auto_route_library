import 'dart:async';

import 'extended_navigator.dart';

abstract class RouteGuard {
  Future<bool> canNavigate(
    ExtendedNavigatorState navigator,
    String routeName,
    Object arguments,
  );
}
