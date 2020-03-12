import 'dart:async';

import 'package:auto_route/auto_route.dart';
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
            onGenerateRoute: (settings) =>
                router.onGenerate(settings, placeHolder),
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
      _NavigationStatesContainer._instance.getRootRouter();

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

  @override
  void initState() {
    super.initState();
    pushReplacementNamed(widget.initialRoute ?? Navigator.defaultRouteName);
  }

  void _addGuard(RouteGuard guard) {
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

  ExtendedNavigatorState getRootRouter() {
    return _navigatorKeys.isNotEmpty ? _navigatorKeys.values.first : null;
  }

  ExtendedNavigatorState get<T extends RouterBase>() {
    return _navigatorKeys[T];
  }
}
