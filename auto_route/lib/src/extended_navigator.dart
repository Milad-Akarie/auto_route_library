import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

class ExtendedNavigator {
  final Map<String, List<Type>> guardedRoutes;

  ExtendedNavigator([this.guardedRoutes]);

  GlobalKey<NavigatorState> _key = GlobalKey<NavigatorState>();
  NavigatorState get _navigator => _key.currentState;
  GlobalKey<NavigatorState> get key => _key;

  @optionalTypeArgs
  Future<T> pushNamed<T extends Object>(String routeName,
      {Object arguments}) async {
    return await _canNavigate(routeName, arguments)
        ? this._navigator.pushNamed<T>(routeName, arguments: arguments)
        : null;
  }

  @optionalTypeArgs
  Future<T> popAndPushNamed<T extends Object, TO extends Object>(
    String routeName, {
    TO result,
    Object arguments,
  }) {
    pop<TO>(result);
    return pushNamed<T>(routeName, arguments: arguments);
  }

  @optionalTypeArgs
  bool pop<T extends Object>([T result]) => _navigator.pop<T>(result);

  Future<bool> canNavigate(String routeName) => _canNavigate(routeName);

  Future<bool> _canNavigate(String routeName, [Object arguments]) async {
    if (guardedRoutes == null || guardedRoutes[routeName] == null) {
      return true;
    }

    for (Type guard in guardedRoutes[routeName]) {
      if (!await NavigationService.getGuardByType(guard)
          .canNavigate(key.currentContext, routeName, arguments)) return false;
    }
    return true;
  }
}
