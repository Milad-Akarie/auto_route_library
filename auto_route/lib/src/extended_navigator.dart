import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ExtendedNavigator<T extends RouterBase> extends Navigator {
  final T router;
  final List<RouteGuard> guards;

  ExtendedNavigator({
    @required this.router,
    this.guards,
    String initialRoute,
    RouteFactory onUnknownRoute,
    Widget placeHolder,
    List<NavigatorObserver> observers,
    Key key,
  }) : super(
            onGenerateRoute: (settings) => router.onGenerateRoute(settings),
            onUnknownRoute: onUnknownRoute,
            initialRoute: initialRoute,
            observers: observers = const <NavigatorObserver>[],
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

  static ExtendedNavigatorState get root =>
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

class ExtendedNavigatorState extends NavigatorState {
  final Map<String, List<Type>> guardedRoutes;
  final _registeredGuards = <Type, RouteGuard>{};

  ExtendedNavigatorState({
    List<RouteGuard> guards,
    this.guardedRoutes,
  }) {
    guards?.forEach(_addGuard);
  }

  void _addGuard(RouteGuard guard) {
    assert(guard != null);
    _registeredGuards[guard.runtimeType] = guard;
  }

  @override
  Future<T> push<T extends Object>(Route<T> route) async {
    print(_hasGuards(route.settings.name));

    if (!_hasGuards(route.settings.name)) {
      return super.push<T>(route);
    }

    if (route.settings.isInitialRoute) {
      super.push(
        PageRouteBuilder(
          transitionDuration: Duration(milliseconds: 0),
          pageBuilder: (_, __, ___) => Container(color: Colors.black),
        ),
      );
      if (await _canNavigate(route.settings)) {
        // await route.popped;
        maybePop();
        // super.pushReplacement(route);
      }
    }

    return await _canNavigate(route.settings) ? super.push<T>(route) : null;
  }

  // @override
  // @optionalTypeArgs
  // Future<T> pushNamed<T extends Object>(String routeName,
  //     {Object arguments}) async {
  //   return await _canNavigate(routeName, arguments)
  //       ? super.pushNamed<T>(routeName, arguments: arguments)
  //       : null;
  // }

  // @override
  // @optionalTypeArgs
  // Future<T> pushReplacementNamed<T extends Object, TO extends Object>(
  //   String routeName, {
  //   TO result,
  //   Object arguments,
  // }) async {
  //   return await _canNavigate(routeName, arguments)
  //       ? super.pushReplacementNamed<T, TO>(routeName,
  //           arguments: arguments, result: result)
  //       : null;
  // }

  // @override
  // @optionalTypeArgs
  // Future<T> popAndPushNamed<T extends Object, TO extends Object>(
  //   String routeName, {
  //   TO result,
  //   Object arguments,
  // }) {
  //   pop<TO>(result);
  //   return pushNamed<T>(routeName, arguments: arguments);
  // }

  // @override
  // @optionalTypeArgs
  // Future<T> pushNamedAndRemoveUntil<T extends Object>(
  //   String newRouteName,
  //   RoutePredicate predicate, {
  //   Object arguments,
  // }) async {
  //   return await _canNavigate(newRouteName, arguments)
  //       ? super.pushNamedAndRemoveUntil<T>(newRouteName, predicate,
  //           arguments: arguments)
  //       : null;
  // }

  // @optionalTypeArgs
  // Future<T> pushNamedAndRemoveUntilRoute<T extends Object>(
  //   String newRouteName,
  //   String anchorRoute, {
  //   Object arguments,
  // }) async {
  //   return pushNamedAndRemoveUntil<T>(
  //       newRouteName, ModalRoute.withName(anchorRoute),
  //       arguments: arguments);
  // }

  bool _hasGuards(String routeName) =>
      guardedRoutes != null && guardedRoutes[routeName] != null;

  Future<bool> canNavigate(String routeName) async =>
      !_hasGuards(routeName) &&
      await _canNavigate(RouteSettings(name: routeName));

  Future<bool> _canNavigate(RouteSettings settings) async {
    assert(guardedRoutes != null);
    for (Type guardType in guardedRoutes[settings.name]) {
      if (!await _getGuard(guardType)
          .canNavigate(this, settings.name, settings.arguments)) return false;
    }
    return true;
  }

  RouteGuard _getGuard(Type guardType) {
    if (_registeredGuards[guardType] == null) {
      throw ('$guardType is not registered!'
          '\nYou have to add your guards to the ExtendedNavigator');
    }
    return _registeredGuards[guardType];
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
    return _navigatorKeys[T] = ExtendedNavigatorState(
      guards: guards,
      guardedRoutes: guardedRoutes,
    );
  }

  ExtendedNavigatorState getRootNavigator() {
    return _navigatorKeys.isNotEmpty ? _navigatorKeys.values.first : null;
  }

  ExtendedNavigatorState get<T extends RouterBase>() {
    return _navigatorKeys[T];
  }
}
