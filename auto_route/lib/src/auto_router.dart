import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class AutoRouter<T extends RouterBase> extends StatefulWidget {
  AutoRouter({
    this.router,
    this.guards,
    this.initialRoute,
    this.onUnknownRoute,
    this.initialRouteArgs,
    this.observers = const <NavigatorObserver>[],
    Key key,
  }) : super(key: key);

  final T router;
  final List<RouteGuard> guards;
  final String initialRoute;
  final RouteFactory onUnknownRoute;
  final Object initialRouteArgs;
  final List<NavigatorObserver> observers;

  @override
  AutoRouterState createState() => AutoRouterState<T>();

  AutoRouter call(_, __) => this;

  static AutoRouterState of(
    BuildContext context, {
    bool rootRouter = false,
    bool nullOk = false,
  }) {
    final AutoRouterState autoRouter =
        rootRouter ? context.findRootAncestorStateOfType<AutoRouterState>() : context.findAncestorStateOfType<AutoRouterState>();
    assert(() {
      if (autoRouter == null && !nullOk) {
        throw FlutterError('AutoRouterState operation requested with a context that does not include a AutoRouterState.\n'
            'The context used to push or pop routes from the AutoRouterState must be that of a '
            'widget that is a descendant of a AutoRouterState widget.');
      }
      return true;
    }());
    return autoRouter;
  }
}

class AutoRouterState<T extends RouterBase> extends State<AutoRouter<T>> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<ExtendedNavigatorState>(debugLabel: T.toString());

  ExtendedNavigatorState get _navigator => _navigatorKey.currentState;

  @override
  Widget build(BuildContext context) {
    return ExtendedNavigator<T>(
      router: widget.router,
      key: _navigatorKey,
      initialRoute: widget.initialRoute,
      initialRouteArgs: widget.initialRouteArgs,
      onUnknownRoute: widget.onUnknownRoute,
      observers: widget.observers,
      guards: widget.guards,
    );
  }

  @optionalTypeArgs
  Future<T> push<T extends Object>(String routeName, {Object arguments, OnNavigationRejected onReject}) =>
      _navigator.pushNamed<T>(routeName, arguments: arguments, onReject: onReject);

  @optionalTypeArgs
  Future<T> replace<T extends Object, TO extends Object>(
    String routeName, {
    TO result,
    Object arguments,
    OnNavigationRejected onReject,
  }) =>
      _navigator.pushReplacementNamed<T, TO>(routeName, arguments: arguments, onReject: onReject);


  @optionalTypeArgs
  Future<T> popAndPush<T extends Object, TO extends Object>(
      String routeName, {
        TO result,
        Object arguments,
      }) {
    pop<TO>(result);
    return push<T>(routeName, arguments: arguments);
  }

  @optionalTypeArgs
  Future<T> pushAndRemoveUntil<T extends Object>(
    String newRouteName,
    RoutePredicate predicate, {
    Object arguments,
    OnNavigationRejected onReject,
  }) =>
      _navigator.pushNamedAndRemoveUntil<T>(newRouteName, predicate, arguments: arguments, onReject: onReject);

  void pop<T extends Object>([T result]) => _navigator.pop<T>(result);

  bool canPop() => _navigator.canPop();

  Future<bool> maybePop<T extends Object>([T result]) => _navigator.maybePop<T>(result);

  void popRoot<T extends Object>([T result]) => _navigator.rootNavigator.pop<T>(result);

  AutoRouterState get parent => AutoRouter.of(context);

  ExtendedNavigatorState<T> get navigator => _navigator;
}
