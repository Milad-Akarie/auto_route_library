import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

part 'router_base.dart';

RectTween _createRectTween(Rect begin, Rect end) {
  return MaterialRectArcTween(begin: begin, end: end);
}

typedef OnNavigationRejected = void Function(RouteGuard guard);

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
            onGenerateInitialRoutes: (NavigatorState navigator, String initialRoute) {
              return generateInitialRoutes(
                navigator as ExtendedNavigatorState,
                initialRoute,
                initialRouteArgs,
              );
            },
            observers: [
              StackObserver(),
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

  static List<Route<dynamic>> generateInitialRoutes(
    ExtendedNavigatorState navigator,
    String initialRouteName,
    Object initialRouteArgs,
  ) {
    final routes = <Route>[];
    final router = navigator.router;
    assert(router != null);
    if (initialRouteName != null) {
      var matcher = RouteMatcher(Uri.parse(initialRouteName));
      var matchingSegments = matcher.matchingSegments(router.allRoutes);

      matchingSegments.matches.forEach((template, segment) {
        RouteData data;
        final matchResults = MatchResult(
          RouteSettings(name: segment),
          uri: Uri.parse(segment),
          template: template,
        );
        if (router.subRouters[template] != null) {
          data = NestedRouteData(
            matchResult: matchResults,
            router: router.subRouters[template](),
            pendingSegments: initialRouteName,
          );
        } else {
          data = RouteData(matchResults);
        }
        var route = router.routesMap[template](data);
        routes.add(route);
      });
    }

    if (routes.isEmpty) {
      routes.add(router.onGenerateRoute(RouteSettings(name: '/')));
    }

    return routes;
  }

  ExtendedNavigator call(_, __) => this;

  static ExtendedNavigatorState ofRouter<T extends RouterBase>() => _NavigationStatesContainer._instance.get<T>();


  static ExtendedNavigatorState get root => _NavigationStatesContainer._instance.getRootNavigator();

  static List<Type> get allKeys => _NavigationStatesContainer._instance._navigatorKeys.keys.toList();

  @Deprecated("renamed to root")
  static ExtendedNavigatorState get rootNavigator => root;

  static ExtendedNavigatorState of(
    BuildContext context, {
    bool rootNavigator = false,
    bool nullOk = false,
  }) {
    final ExtendedNavigatorState navigator =
        rootNavigator ? context.findRootAncestorStateOfType<ExtendedNavigatorState>() : context.findAncestorStateOfType<ExtendedNavigatorState>();
    assert(() {
      if (navigator == null && !nullOk) {
        throw FlutterError('ExtendedNavigator operation requested with a context that does not include a ExtendedNavigator.\n'
            'The context used to push or pop routes from the ExtendedNavigator must be that of a '
            'widget that is a descendant of a ExtendedNavigator widget.');
      }
      return true;
    }());
    return navigator;
  }
}

class ExtendedNavigatorState<T extends RouterBase> extends NavigatorState with WidgetsBindingObserver {
  final Map<String, List<Type>> _guardedRoutes;
  final _registeredGuards = <Type, RouteGuard>{};

  StackObserver _stackObserver;

  final RouterBase _router;

  ExtendedNavigatorState(
    this._router, {
    List<RouteGuard> guards,
  }) : _guardedRoutes = _router.guardedRoutes {
    guards?.forEach(_registerGuard);
  }

  T get router => _router;

  ExtendedNavigatorState get parent => context.findAncestorStateOfType<ExtendedNavigatorState>();

  @override
  void initState() {
    _router._onRePushInitialRoute = (RouteSettings settings) {
      pushReplacementNamed(settings.name, arguments: settings.arguments);
    };
    super.initState();
    _stackObserver = widget.observers.whereType<StackObserver>().first;
    final parentNavigator = parent;
    if (parentNavigator == null) {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  Future<dynamic> pushDeepLink(String url) async {
    return _pushDeepLink(Uri.tryParse(url));
  }

  Future<dynamic> _pushDeepLink(Uri uri) {
    var matcher = RouteMatcher(uri);
    var matchResult = matcher.matchingSegments(_router.allRoutes);

    if (!matchResult.hasFullMatch) {
      print(matchResult.matches);
//      throw FlutterError("Failed to push deepLink $uri");
    }

    matchResult.matches.forEach((template, segment) {
      RouteData data;
      final matchResults = MatchResult(
        RouteSettings(name: segment),
        uri: Uri.parse(segment),
        template: template,
      );
      if (_router.subRouters[template] != null) {
        data = NestedRouteData(
          matchResult: matchResults,
          router: _router.subRouters[template](),
          pendingSegments: uri.toString(),
        );
      } else {
        data = RouteData(matchResults);
      }
      var route = _router.routesMap[template](data);
      push(route);
    });
  }

  bool get isRoot => parent == null;
  WillPopCallback _willPopCallback;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modelRoute = ModalRoute.of(context);
    if (modelRoute != null) {
      modelRoute.addScopedWillPopCallback(_willPopCallback = () async {
        return !await maybePop();
      });
    }
  }

  void _registerGuard(RouteGuard guard) {
    assert(guard != null);
    _registeredGuards[guard.runtimeType] = guard;
  }

  @override
  @optionalTypeArgs
  Future<T> pushNamed<T extends Object>(String routeName, {Object arguments, OnNavigationRejected onReject}) async {
    return await _canNavigate(
      routeName,
      arguments: arguments,
      onReject: onReject,
    )
        ? super.pushNamed<T>(
            routeName,
            arguments: arguments,
          )
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
    return await _canNavigate(routeName, arguments: arguments, onReject: onReject)
        ? super.pushReplacementNamed<T, TO>(routeName, arguments: arguments, result: result)
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
    return await _canNavigate(newRouteName, arguments: arguments, onReject: onReject)
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

  Future<bool> _canNavigate(String routeName, {Object arguments, OnNavigationRejected onReject}) async {
    if (!_router._hasGuards(routeName)) {
      return true;
    }
    for (Type guardType in _guardedRoutes[routeName]) {
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
    if (_willPopCallback != null) {
      ModalRoute.of(context).removeScopedWillPopCallback(_willPopCallback);
    }
    super.deactivate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class _NavigationStatesContainer {
  // ensure we only have one instance of the container
  static final _NavigationStatesContainer _instance = _NavigationStatesContainer._();
  final Map<Type, ExtendedNavigatorState> _navigatorKeys = {};

  ExtendedNavigatorState operator  [](Type type) => _navigatorKeys[type];
  _NavigationStatesContainer._();

  ExtendedNavigatorState create<T extends RouterBase>(
    List<RouteGuard> guards,
    RouterBase router,
  ) {
    print('creating navigation state for ${router.runtimeType}');
    return _navigatorKeys[router.runtimeType] = ExtendedNavigatorState<T>(
      router,
      guards: guards,
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

class StackObserver extends NavigatorObserver {
  final stack = <Route>[];

  List<String> get history => stack.map((r) => r.settings.name).toList();

  String get current => history.last;

  @override
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
//    print("did push ${route.settings.name}");
    stack.add(route);
//    print(history);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic> previousRoute) {
//    print("did pop ${route.settings.name}");
    stack.remove(route);
//    print(history);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic> previousRoute) {
//    print("did remove ${route.settings.name}");
    stack.remove(route);
//    print(history);
  }

  @override
  void didReplace({Route<dynamic> newRoute, Route<dynamic> oldRoute}) {
    final index = stack.indexOf(oldRoute);
    stack[index] = newRoute;
    print(history);
  }
}

class NestedNavigator extends StatelessWidget {
  final String initialRoute;

  const NestedNavigator({Key key, this.initialRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final routeData = RouteData.of(context);
    if (routeData is! NestedRouteData) {
      throw FlutterError("failed to hook nested navigator");
    }
    var nestedRouteData = routeData as NestedRouteData;
    return ExtendedNavigator(
      router: nestedRouteData.router,
      initialRoute: nestedRouteData.pendingSegments ?? initialRoute,
      key: key,
    );
  }
}
