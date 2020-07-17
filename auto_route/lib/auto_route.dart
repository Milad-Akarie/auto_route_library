library auto_route;

import 'package:auto_route/src/extended_navigator.dart';
import 'package:flutter/widgets.dart' show BuildContext;

import 'src/route_guard.dart';

export 'src/auto_route_wrapper.dart';
export 'src/extended_navigator.dart';
export 'src/parameters.dart';
export 'src/route_data.dart';
export 'src/route_def.dart';
export 'src/route_guard.dart';
export 'src/router_base.dart';
export 'src/router_utils.dart';
export 'src/transitions_builders.dart';

typedef OnNavigationRejected = void Function(RouteGuard guard);

extension BuildContextX on BuildContext {
  ExtendedNavigatorState get navigator =>
      ExtendedNavigator.of(this, nullOk: true);
  ExtendedNavigatorState get rootNavigator =>
      ExtendedNavigator.of(this, rootRouter: true, nullOk: true);
}
