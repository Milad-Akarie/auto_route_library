import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class AutoRouter<T extends RouteGenerator> extends StatefulWidget  {
  AutoRouter({
    this.routeGenerator,
    this.guards = const [],
    this.name,
    this.basePath,
    this.initialRoute,
    this.onUnknownRoute,
    this.initialRouteArgs,
    this.navigatorKey,
    this.observers = const <NavigatorObserver>[],
    Key key,
  }):super(key: key);

  final GlobalKey<NavigatorState> navigatorKey;
  final List<NavigatorObserver> observers;
  final RouteFactory onUnknownRoute;
  final String initialRoute;
  final Object initialRouteArgs;
  final T routeGenerator;
  final List<RouteGuard> guards;
  final String basePath;
  final String name;

  @override
  AutoRouterState createState() => AutoRouterState<T>();

  static get _placeHolderRoute => PageRouteBuilder(
        pageBuilder: (_, __, ___) => Container(color: Colors.white),
      );

  static List<Route<dynamic>> generateInitialRoutes(
    AutoRouterState router,
    String initialRouteName,
    Object initialRouteArgs,
  ) {
    var initialRoutes = <Route>[];
    assert(initialRouteName != null);
    var navigator = router._navigator;
    if (!kIsWeb && initialRouteName.startsWith('/') && initialRouteName.length > 1) {
      var rootRoute = navigator.widget.onGenerateRoute(RouteSettings(name: '/'));
      if (rootRoute != null) {
        if ((rootRoute.settings as RouteData).routeMatch.hasGuards) {
          initialRoutes.add(_placeHolderRoute);
          router._guardedInitialRoutes.add(rootRoute);
        } else {
          initialRoutes.add(rootRoute);
        }
      }
    }

    var settings = RouteSettings(name: initialRouteName, arguments: initialRouteArgs);
    var route = navigator.widget.onGenerateRoute(settings);

    if (route != null) {
      var data = route.settings as RouteData;
      if (router._guardedInitialRoutes.isNotEmpty || data.routeMatch.hasGuards) {
        router._guardedInitialRoutes.add(route);
        if (initialRoutes.isEmpty) {
          initialRoutes.add(_placeHolderRoute);
        }
      } else {
        initialRoutes.add(route);
      }
    } else {
      var unknownRoute = navigator.widget.onUnknownRoute(settings);
      initialRoutes.add(unknownRoute);
    }

    initialRoutes.removeWhere((route) => route == null);
    return initialRoutes;
  }

  AutoRouter<T> call(_, navigator) => this;
  static TransitionBuilder builder({
    @required RouteGenerator generator,
    String initialRoute,
    List<RouteGuard> guards,
  }) =>
      (_, widget) {
        assert(widget is Navigator);
        var navigator = widget as Navigator;

        return AutoRouter(
          key: Key("AutoRouter"),
          navigatorKey: navigator.key,
          routeGenerator: generator,
          guards: guards,
          onUnknownRoute: navigator.onUnknownRoute,
          observers: navigator.observers,
          initialRoute: WidgetsBinding.instance.window.defaultRouteName != Navigator.defaultRouteName
              ? WidgetsBinding.instance.window.defaultRouteName
              : initialRoute ?? WidgetsBinding.instance.window.defaultRouteName,
        );
      };


  static AutoRouterState named(String name) {
    assert(name != null);
    return _RoutersContainer._instance.get(name);
  }

  static AutoRouterState get root => _RoutersContainer._instance.getRootRouter();

  static AutoRouterState of(
    BuildContext context, {
    bool rootNavigator = false,
    bool nullOk = false,
  }) {
    final AutoRouterState router = rootNavigator ? context.findRootAncestorStateOfType<AutoRouterState>() : context.findAncestorStateOfType<AutoRouterState>();
    assert(() {
      if (router == null && !nullOk) {
        throw FlutterError('Router operation requested with a context that does not include an Router.\n'
            'The context used to push or pop routes from the Router must be that of a '
            'widget that is a descendant of a Router widget.');
      }
      return true;
    }());
    return router;
  }
}

class AutoRouterState<T extends RouteGenerator> extends State<AutoRouter<T>> with WidgetsBindingObserver{
  final _registeredGuards = <Type, RouteGuard>{};
  T routeGenerator;
  List<Route> _guardedInitialRoutes = [];

  AutoRouterState get parent => _parent;

  AutoRouterState _parent;
  final children = <AutoRouterState>[];
  GlobalKey<NavigatorState> _navigatorKey;

  NavigatorState get _navigator => _navigatorKey.currentState;

  bool get isRoot => parent == null;

  WillPopCallback _willPopCallback;

  AutoRouterState get root => context.findRootAncestorStateOfType<AutoRouterState>() ?? this;

  @override
  void initState() {
    super.initState();
     WidgetsBinding.instance.addObserver(this);
    print(_guardedInitialRoutes);
    _updateNavigator();
    if (_guardedInitialRoutes.isNotEmpty) {
      _pushAllGuarded(_guardedInitialRoutes);
    }
  }


  Future<void> _pushAllGuarded(Iterable<Route> routes) async {
    for (var route in routes) {
      var data = (route.settings as RouteData);
      if (await _canNavigate(data.template)) {
        if (data.template == Navigator.defaultRouteName) {
          _navigator.pushReplacement(route);
        } else {
          _navigator.push(route);
        }
      } else {
        break;
      }
    }
  }

  // On Android: the user has pressed the back button.
  @override
  Future<bool> didPopRoute() async {
    assert(mounted);
    if (_navigator == null)
      return false;
    return await _navigator.maybePop();
  }

  @override
  Future<bool> didPushRoute(String route) async {
    print("did push Route $route");
    assert(mounted);
    if (_navigator == null)
      return false;
    push(route);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    routeGenerator = widget.routeGenerator;
    var initial = widget.initialRoute;
    var basePath;

    if (routeGenerator == null) {
      var parentData = ParentRouteData.of(context);
      if (parentData != null) {
        routeGenerator = parentData.routeGenerator;
        basePath = parentData.path;
        if (parentData.initialRoute?.isNotEmpty == true) {
          initial = parentData.initialRoute;
        }
      }
    }

    assert(routeGenerator != null);
    return Navigator(
      key: _navigatorKey,
      initialRoute: initial,
      observers: widget.observers,
      onGenerateRoute: (RouteSettings settings){
        return routeGenerator.onGenerateRoute(settings,basePath);
      },
      onGenerateInitialRoutes: (NavigatorState navigator, String initialRoute) {
        return AutoRouter.generateInitialRoutes(
          this,
          initialRoute,
          widget.initialRouteArgs,
        );
      },
    );
  }

  void _updateNavigator() {
    _navigatorKey = widget.navigatorKey ?? GlobalObjectKey<NavigatorState>(this);
  }

  @override
  void didUpdateWidget(AutoRouter<T> oldWidget) {
    _updateNavigator();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _parent = context.findAncestorStateOfType<AutoRouterState>();
    if (_parent != null) {
      _parent.children.add(this);
      if(_parent._registeredGuards != null){
        _registeredGuards.addAll(_parent._registeredGuards);
      }
    }
    widget.guards?.forEach(_registerGuard);

    _RoutersContainer._instance.register(this, name: widget.name);
    final modelRoute = ModalRoute.of(context);
    if (modelRoute != null) {
      modelRoute.addScopedWillPopCallback(_willPopCallback = () async {
        return !await _navigator.maybePop();
      });
    }
  }

  void _registerGuard(RouteGuard guard) {
    assert(guard != null);
    _registeredGuards[guard.runtimeType] = guard;
  }

  @optionalTypeArgs
  Future<T> push<T extends Object>(String routeName, {Object arguments, OnNavigationRejected onReject}) async {
    return await _canNavigate(
      routeName,
      arguments: arguments,
      onReject: onReject,
    )
        ? _navigator.pushNamed<T>(routeName, arguments: arguments)
        : null;
  }

  @optionalTypeArgs
  Future<T> replace<T extends Object, TO extends Object>(
    String routeName, {
    TO result,
    Object arguments,
    OnNavigationRejected onReject,
  }) async {
    return await _canNavigate(routeName, arguments: arguments, onReject: onReject)
        ? _navigator.pushReplacementNamed<T, TO>(routeName, arguments: arguments, result: result)
        : null;
  }

  @optionalTypeArgs
  Future<T> pushAndRemoveUntil<T extends Object>(
    String newRouteName,
    RoutePredicate predicate, {
    Object arguments,
    OnNavigationRejected onReject,
  }) async {
    return await _canNavigate(newRouteName, arguments: arguments, onReject: onReject)
        ? _navigator.pushNamedAndRemoveUntil<T>(
            newRouteName,
            predicate,
            arguments: arguments,
          )
        : null;
  }

  @optionalTypeArgs
  Future<T> pushAndRemoveUntilPath<T extends Object>(
    String newRouteName,
    String anchorPath, {
    Object arguments,
    OnNavigationRejected onReject,
  }) async {
    return await _canNavigate(newRouteName, arguments: arguments, onReject: onReject)
        ? _navigator.pushNamedAndRemoveUntil<T>(
            newRouteName,
            RouteData.withPath(anchorPath),
            arguments: arguments,
          )
        : null;
  }

  void popUntilPath(String path) {
    _navigator.popUntil(RouteData.withPath(path));
  }

  void popUntil(RoutePredicate predicate) {
    _navigator.popUntil(predicate);
  }

  void popUntilRoot() {
    _navigator.popUntil((route) => route.isFirst);
  }

  @optionalTypeArgs
  void pop<T extends Object>([T result]) {
    _navigator.pop<T>(result);
  }

  Future<bool> canNavigate(String routeName) => _canNavigate(routeName);

  Future<bool> _canNavigate(String routeName, {Object arguments, OnNavigationRejected onReject}) async {
    var match = routeGenerator.findMatch(RouteSettings(name: routeName));
    if (match == null || !match.hasGuards) {
      return true;
    }

    for (Type guardType in match.routeDef.guards) {
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
          '\nYou have to add your guards to AutoRouter widget');
    }
    return _registeredGuards[guardType];
  }

  @override
  void deactivate() {
    if (_willPopCallback != null) {
      ModalRoute.of(context).removeScopedWillPopCallback(_willPopCallback);
    }
    super.deactivate();
  }

  @override
  void dispose() {
    if (_parent != null) {
      _parent.children.remove(this);
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class _RoutersContainer {
  // ensure we only have one instance of the container
  static final _RoutersContainer _instance = _RoutersContainer._();
  final Map<String, AutoRouterState> _routers = {};

  AutoRouterState operator [](Type type) => _routers[type];

  _RoutersContainer._();

  void register(AutoRouterState router, {String name}) {
    _routers[name ?? router.widget.routeGenerator.runtimeType.toString()] = router;
  }

  AutoRouterState getRootRouter() {
    if (_routers.isNotEmpty) {
      return _routers.values.first.root;
    }
    return null;
  }

  AutoRouterState remove<T extends RouteGenerator>() {
    return _routers.remove(T.toString());
  }

  AutoRouterState get<T extends RouteGenerator>([String name]) {
    return _routers[name ?? T.toString()];
  }
}

//class NestedNavigator extends StatelessWidget {
//  const NestedNavigator({
//    Key key,
//    this.initialRoute,
//    this.guards = const [],
//    this.onUnknownRoute,
//    this.name,
//    this.observers = const <NavigatorObserver>[],
//  }) : super(key: key);
//
//  final String initialRoute;
//  final List<RouteGuard> guards;
//  final List<NavigatorObserver> observers;
//  final RouteFactory onUnknownRoute;
//  final String name;
//
//  @override
//  Widget build(BuildContext context) {
//    var initial = initialRoute;
//    var basePath = '';
//    var parentData = ParentRouteData.of(context);
//    if (parentData != null) {
//      basePath = parentData.path;
//      if (parentData.initialRoute?.isNotEmpty == true) {
//        initial = parentData.initialRoute;
//      }
//    } else {
//      throw FlutterError('Router can not be null');
//    }
//    var parentNav = ExtendedNavigator.of(context).widget;
//    return ExtendedNavigator(
//      router: parentData.routeGenerator,
//      name: name,
//      initialRoute: initial,
//      basePath: basePath,
//      onUnknownRoute: onUnknownRoute ?? parentNav.onUnknownRoute,
//      guards: [
//        ...guards,
//        if (parentNav.guards != null) ...parentNav.guards,
//      ],
//      observers: observers,
//      initialRouteArgs: parentData._initialArgsToPass,
//      key: key,
//    );
//  }
//}
