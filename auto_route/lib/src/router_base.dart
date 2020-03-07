import 'package:flutter/material.dart';

abstract class RouterBase {
  Map<String, List<Type>> get guardedRoutes => null;
  Route<dynamic> onGenerateRoute(RouteSettings settings);

  // final _navigatorKey = GlobalKey<ExtendedNavigatorState>();
  // GlobalKey<ExtendedNavigatorState> get navigatorKey => _navigatorKey;
  // ExtendedNavigatorState get navigatorState => navigatorKey.currentState;
}
