import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

part 'router_base.dart';

RectTween _createRectTween(Rect begin, Rect end) {
  return MaterialRectArcTween(begin: begin, end: end);
}

typedef OnNavigationRejected = Function(RouteGuard guard);

class ExtendedNavigator<T extends RouterBase> extends Navigator {
  ExtendedNavigator({
    @required this.router,
    this.guards,
    String initialRoute,
    RouteFactory onUnknownRoute,
    Object initialRouteArgs,
    List<NavigatorObserver> observers = const <NavigatorObserver>[],
    Key key,
  })  : assert(router != null),
        assert(observers != null),
        super(
            onGenerateRoute: (settings) => router._onGenerateRoute(
                  settings,
                  initialRouteArgs,
                ),
            onUnknownRoute: onUnknownRoute,
            initialRoute: initialRoute,
            observers: [
              HeroController(createRectTween: _createRectTween),
              ...observers,
            ],
            key: key);

  final T router;
  final List<RouteGuard> guards;

  @override
  ExtendedNavigatorState createState() {
    return _NavigationStatesContainer._instance.create<T>(
      guards,
      router,
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

class ExtendedNavigatorState<T extends RouterBase> extends NavigatorState
    with WidgetsBindingObserver {
  final Map<String, List<Type>> guardedRoutes;
  final _registeredGuards = <Type, RouteGuard>{};
  final RouterBase router;

  ExtendedNavigatorState({
    List<RouteGuard> guards,
    this.router,
  }) : guardedRoutes = router.guardedRoutes {
    guards?.forEach(_registerGuard);
  }

  @override
  void initState() {
    router._onRePushInitialRoute = (RouteSettings settings) {
      pushReplacementNamed(settings.name, arguments: settings.arguments);
    };
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Future<T> push<T extends Object>(Route<T> route) async {
    return super.push<T>(route..settings);
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

  // On soft back button pressed in Android
  @override
  Future<bool> didPopRoute() {
    assert(mounted);
    return maybePop();
  }

  @override
  Future<bool> didPushRoute(String route) async {
    assert(mounted);
    pushNamed(route);
    return true;
  }

  Future<bool> canNavigate(String routeName) => _canNavigate(routeName);

  Future<bool> _canNavigate(String routeName,
      {Object arguments, OnNavigationRejected onReject}) async {
    if (!router._hasGuards(routeName)) {
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
  void deactivate() {
    super.deactivate();
    _NavigationStatesContainer._instance.remove<T>();
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }
}

class _NavigationStatesContainer {
  // ensure we only have one instance of the container
  static final _NavigationStatesContainer _instance =
      _NavigationStatesContainer._();
  final Map<Type, ExtendedNavigatorState> _navigatorKeys = {};

  _NavigationStatesContainer._();

  ExtendedNavigatorState create<T extends RouterBase>(
      List<RouteGuard> guards, RouterBase router) {
    return _navigatorKeys[T] = ExtendedNavigatorState<T>(
      guards: guards,
      router: router,
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
