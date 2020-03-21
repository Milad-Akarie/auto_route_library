import 'package:flutter/material.dart';

abstract class RouterBase {
  Map<String, List<Type>> get guardedRoutes => null;
  Route<dynamic> onGenerateRoute(RouteSettings settings);
}
