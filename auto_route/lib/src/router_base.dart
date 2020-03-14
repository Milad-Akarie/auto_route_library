import 'package:flutter/material.dart';

abstract class RouterBase {
  bool _initalRouteFired = false;
  Map<String, List<Type>> get guardedRoutes => null;

  Route<dynamic> onGenerate(RouteSettings settings, [Widget placeHolder]) {
    if (settings.isInitialRoute && !_initalRouteFired) {
      _initalRouteFired = true;
      return PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            placeHolder ?? Container(color: Colors.red),
      );
    }
    return onGenerateRoute(settings);
  }

  Route<dynamic> onGenerateRoute(RouteSettings settings);
}
