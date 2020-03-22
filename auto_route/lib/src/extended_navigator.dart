import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

RectTween _createRectTween(Rect begin, Rect end) {
  return MaterialRectArcTween(begin: begin, end: end);
}

typedef OnNavigationRejected = Function(RouteGuard guard);

class ExtendedNavigator<T extends RouterBase> extends Navigator {
  final T router;
  final List<RouteGuard> guards;

  ExtendedNavigator({
    @required this.router,
    this.guards,
    String initialRoute,
    RouteFactory onUnknownRoute,
    List<NavigatorObserver> observers = const <NavigatorObserver>[],
    Key key,
  })  : assert(observers != null),
        super(
            onGenerateRoute: router.onGenerateRoute,
            onUnknownRoute: onUnknownRoute,
            initialRoute: initialRoute,
            observers: [
              HeroController(createRectTween: _createRectTween),
              ...observers,
            ],
            key: key);

  @override
  ExtendedNavigatorState createState() {
    return _NavigationStatesContainer._instance.create<T>(
      guards,
      router.guardedRoutes,
    );
  }

  ExtendedNavigator call(_, __) => this;

  static ExtendedNavigatorState ofRouter<T extends RouterBase>() =>
      _NavigationStatesContainer._instance.get<T>();

  static ExtendedNavigatorState get rootNavigator =>
      _NavigationStatesContainer._instance.getRootNavigator();

  static ExtendedNavigatorState of(
    BuildContext context, {
    bool rootNavigator = false,
    bool nullOk = false,
  }) {
    final ExtendedNavigatorState navigator = rootNavigator
        ? context.findRootAncestorStateOfType<ExtendedNavigatorState>()
        : context.findAncestorStateOfType<ExtendedNavigatorState>();
    assert(() {
      if (navigator == null && !nullOk) {
        throw FlutterError(
            'ExtendedNavigator operation requested with a context that does not include a ExtendedNavigator.\n'
            'The context used to push or pop routes from the ExtendedNavigator must be that of a '
            'widget that is a descendant of a ExtendedNavigator widget.');
      }
      return true;
    }());
    return navigator;
  }
}

class ExtendedNavigatorState<T extends RouterBase> extends NavigatorState {
  final Map<String, List<Type>> guardedRoutes;
  final _registeredGuards = <Type, RouteGuard>{};

  ExtendedNavigatorState({
    List<RouteGuard> guards,
    this.guardedRoutes,
  }) {
    guards?.forEach(_registerGuard);
  }

  /// if initial route is guarded we push
  /// a placeholder route until next distention is
  /// decided by the route guard
  final _redirectInitialRoute = 'redirect-intial-route';
  @override
  Future<T> push<T extends Object>(Route<T> route) async {
    final routeName = route.settings.name;
    if (routeName == '/' &&
        _hasGuards(routeName) &&
        route.settings.arguments != _redirectInitialRoute) {
      super.push<T>(
        PageRouteBuilder<T>(
          transitionDuration: const Duration(milliseconds: 0),
          pageBuilder: (_, __, ___) => Container(
            color: Colors.white,
          ),
        ),
      );

      return pushReplacementNamed(route.settings.name,
          arguments: _redirectInitialRoute);
    }
    return super.push<T>(route);
  }

  void _registerGuard(RouteGuard guard) {
    assert(guard != null);
    _registeredGuards[guard.runtimeType] = guard;
  }

  @override
  @optionalTypeArgs
  Future<T> pushNamed<T extends Object>(String routeName,
      {Object arguments, OnNavigationRejected onReject}) async {
    return await _canNavigate(routeName,
            arguments: arguments, onReject: onReject)
        ? super.pushNamed<T>(routeName, arguments: arguments)
        : null;
  }

  @override
  @optionalTypeArgs
  Future<T> pushReplacementNamed<T extends Object, TO extends Object>(
    String routeName, {
    TO result,
    Object arguments,
    OnNavigationRejected onReject,
  }) async {
    return await _canNavigate(routeName,
            arguments: arguments, onReject: onReject)
        ? super.pushReplacementNamed<T, TO>(routeName,
            arguments: arguments, result: result)
        : null;
  }

  @override
  @optionalTypeArgs
  Future<T> pushNamedAndRemoveUntil<T extends Object>(
    String newRouteName,
    RoutePredicate predicate, {
    Object arguments,
    OnNavigationRejected onReject,
  }) async {
    return await _canNavigate(newRouteName,
            arguments: arguments, onReject: onReject)
        ? super.pushNamedAndRemoveUntil<T>(
            newRouteName,
            predicate,
            arguments: arguments,
          )
        : null;
  }

  bool _hasGuards(String routeName) =>
      routeName != null &&
      guardedRoutes != null &&
      guardedRoutes[routeName] != null;

  Future<bool> canNavigate(String routeName) => _canNavigate(routeName);

  Future<bool> _canNavigate(String routeName,
      {Object arguments, OnNavigationRejected onReject}) async {
    if (!_hasGuards(routeName)) {
      return true;
    }
    for (Type guardType in guardedRoutes[routeName]) {
      if (!await _getGuard(guardType).canNavigate(this, routeName, arguments)) {
        if (onReject != null) {
          onReject(_getGuard(guardType));
        }
        return false;
      }
    }
    return true;
  }

  RouteGuard _getGuard(Type guardType) {
    if (_registeredGuards[guardType] == null) {
      throw ('$guardType is not registered!'
          '\nYou have to add your guards to ExtendedNavigator widget');
    }
    return _registeredGuards[guardType];
  }

  @override
  void dispose() {
    super.dispose();
    _NavigationStatesContainer._instance.remove<T>();
  }
}

class _NavigationStatesContainer {
  // ensure we only have one instance of the container
  static final _NavigationStatesContainer _instance =
      _NavigationStatesContainer._();
  final Map<Type, ExtendedNavigatorState> _navigatorKeys = {};

  _NavigationStatesContainer._();

  ExtendedNavigatorState create<T extends RouterBase>(
      List<RouteGuard> guards, Map<String, List<Type>> guardedRoutes) {
    return _navigatorKeys[T] = ExtendedNavigatorState<T>(
      guards: guards,
      guardedRoutes: guardedRoutes,
    );
  }

  ExtendedNavigatorState getRootNavigator() {
    return _navigatorKeys.isNotEmpty ? _navigatorKeys.values.first : null;
  }

  ExtendedNavigatorState remove<T extends RouterBase>() {
    return _navigatorKeys.remove(T);
  }

  ExtendedNavigatorState get<T extends RouterBase>() {
    return _navigatorKeys[T];
  }
}
