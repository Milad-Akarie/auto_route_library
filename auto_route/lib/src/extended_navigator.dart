import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

class ExtendedNavigator extends Navigator {
  final RouterBase router;
  final List<RouteGuard> guards;

  ExtendedNavigator({
    @required this.router,
    this.guards,
    String initialRoute,
    RouteFactory onUnknownRoute,
    List<NavigatorObserver> observers,
  }) : super(
            onGenerateRoute: router.onGenerateRoute,
            onUnknownRoute: onUnknownRoute,
            initialRoute: initialRoute,
            observers: observers = const <NavigatorObserver>[]);

  @override
  ExtendedNavigatorState createState() {
    return ExtendedNavigatorState(
      guards: guards,
      guardedRoutes: router.guardedRoutes,
    );
  }

  ExtendedNavigator call(_, __) => this;

  static ExtendedNavigatorState of(
    BuildContext context, {
    bool rootNavigator = false,
    bool nullOk = false,
  }) {
    final NavigatorState navigator = rootNavigator
        ? context.findRootAncestorStateOfType<ExtendedNavigatorState>()
        : context.findAncestorStateOfType<ExtendedNavigatorState>();
    assert(() {
      if (navigator == null && !nullOk) {
        throw FlutterError(
            'Navigator operation requested with a context that does not include a Navigator.\n'
            'The context used to push or pop routes from the Navigator must be that of a '
            'widget that is a descendant of a Navigator widget.');
      }
      return true;
    }());
    return navigator;
  }
}

class ExtendedNavigatorState extends NavigatorState {
  @override
  void initState() {
    super.initState();
    pushReplacementNamed(widget.initialRoute);
  }

  final Map<String, List<Type>> guardedRoutes;
  // final _key = GlobalKey<NavigatorState>();
  final _registeredGuards = <Type, RouteGuard>{};

  ExtendedNavigatorState({List<RouteGuard> guards, this.guardedRoutes}) {
    guards?.forEach(addGuard);
  }

  // NavigatorState get _navigator => _key.currentState;
  // GlobalKey<NavigatorState> get key => _key;

  void addGuard(RouteGuard guard) {
    assert(guard != null);
    _registeredGuards[guard.runtimeType] = guard;
  }

  @override
  @optionalTypeArgs
  Future<T> pushNamed<T extends Object>(String routeName,
      {Object arguments}) async {
    print('pushing $routeName');
    return await _canNavigate(routeName, arguments)
        ? super.pushNamed<T>(routeName, arguments: arguments)
        : null;
  }

  @override
  @optionalTypeArgs
  Future<T> pushReplacementNamed<T extends Object, TO extends Object>(
    String routeName, {
    TO result,
    Object arguments,
  }) async {
    print("pushing replacement");
    return await _canNavigate(routeName, arguments)
        ? super.pushReplacementNamed<T, TO>(routeName,
            arguments: arguments, result: result)
        : null;
  }

  @override
  @optionalTypeArgs
  Future<T> popAndPushNamed<T extends Object, TO extends Object>(
    String routeName, {
    TO result,
    Object arguments,
  }) {
    pop<TO>(result);
    return pushNamed<T>(routeName, arguments: arguments);
  }

  @override
  @optionalTypeArgs
  Future<T> pushNamedAndRemoveUntil<T extends Object>(
    String newRouteName,
    RoutePredicate predicate, {
    Object arguments,
  }) async {
    return await _canNavigate(newRouteName, arguments)
        ? super.pushNamedAndRemoveUntil<T>(newRouteName, predicate,
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

  // /// This returns dynamic because there was a breaking change
  // /// in [NavigatorState] in flutter 1.15.+ and it now returns void
  // /// instead of bool

  // @optionalTypeArgs
  // dynamic pop<T extends Object>([T result]) => _navigator.pop<T>(result);

  Future<bool> canNavigate(String routeName) => _canNavigate(routeName);

  Future<bool> _canNavigate(String routeName, [Object arguments]) async {
    if (guardedRoutes == null || guardedRoutes[routeName] == null) {
      return true;
    }

    for (Type guardType in guardedRoutes[routeName]) {
      if (!await _getGuard(guardType).canNavigate(this, routeName, arguments))
        return false;
    }
    return true;
  }

  RouteGuard _getGuard(Type guardType) {
    if (_registeredGuards[guardType] == null) {
      throw ('$guardType is not registered!'
          '\nYou have to add your guards to the navigator by calling navigator.addGuard()');
    }
    return _registeredGuards[guardType];
  }
}
