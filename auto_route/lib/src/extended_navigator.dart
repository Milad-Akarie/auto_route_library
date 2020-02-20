import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

class ExtendedNavigator {
  final Map<String, List<Type>> _guardedRoutes;
  final _key = GlobalKey<NavigatorState>();
  final _registeredGuards = <Type, RouteGuard>{};

  ExtendedNavigator([this._guardedRoutes]);

  NavigatorState get _navigator => _key.currentState;
  GlobalKey<NavigatorState> get key => _key;
  Map<Type, RouteGuard> get registeredGuards => _registeredGuards;

  void addGuard(RouteGuard guard) {
    assert(guard != null);
    _registeredGuards[guard.runtimeType] = guard;
  }

  @optionalTypeArgs
  Future<T> pushNamed<T extends Object>(String routeName,
      {Object arguments}) async {
    return await _canNavigate(routeName, arguments)
        ? this._navigator.pushNamed<T>(routeName, arguments: arguments)
        : null;
  }

  @optionalTypeArgs
  Future<T> pushReplacementNamed<T extends Object, TO extends Object>(
    String routeName, {
    TO result,
    Object arguments,
  }) async {
    return await _canNavigate(routeName, arguments)
        ? this._navigator.pushReplacementNamed<T, TO>(routeName,
            arguments: arguments, result: result)
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
  Future<T> pushNamedAndRemoveUntil<T extends Object>(
    String newRouteName,
    RoutePredicate predicate, {
    Object arguments,
  }) async {
    return await _canNavigate(newRouteName, arguments)
        ? this._navigator.pushNamedAndRemoveUntil<T>(newRouteName, predicate,
            arguments: arguments)
        : null;
  }

  @optionalTypeArgs
  Future<T> pushNamedAndRemoveUntilRoute<T extends Object>(
    String newRouteName,
    String anchorRoute, {
    Object arguments,
  }) async {
    return pushNamedAndRemoveUntil<T>(
        newRouteName, ModalRoute.withName(anchorRoute),
        arguments: arguments);
  }

  @optionalTypeArgs
  bool pop<T extends Object>([T result]) => _navigator.pop<T>(result);

  bool canPop() => _navigator.canPop();

  @optionalTypeArgs
  Future<bool> maybePop<T extends Object>([T result]) async {
    return _navigator.maybePop(result);
  }

  void popUntil(RoutePredicate predicate) {
    _navigator.popUntil(predicate);
  }

  Future<bool> canNavigate(String routeName) => _canNavigate(routeName);

  Future<bool> _canNavigate(String routeName, [Object arguments]) async {
    if (_guardedRoutes == null || _guardedRoutes[routeName] == null) {
      return true;
    }

    for (Type guardType in _guardedRoutes[routeName]) {
      if (!await _getGuard(guardType)
          .canNavigate(key.currentContext, routeName, arguments)) return false;
    }
    return true;
  }

  RouteGuard _getGuard(Type guardType) {
    if (_registeredGuards[guardType] == null) {
      throw ('$guardType is not registered! \nYou have to add your guards to the navigator by calling navigator.addGaurd()');
    }
    return _registeredGuards[guardType];
  }
}
