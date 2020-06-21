import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/route_matcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

part 'parameters.dart';

part 'route_data.dart';

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
    this.basePath,
    RouteFactory onUnknownRoute,
    Object initialRouteArgs,
    List<NavigatorObserver> observers = const <NavigatorObserver>[],
    Key key,
  })  : assert(router != null),
        assert(observers != null),
        super(
            onGenerateRoute: (settings) {
              return router.onGenerateRoute(
                settings,
                basePath,
              );
            },
            onUnknownRoute: onUnknownRoute ?? defaultUnknownRoutePage,
            initialRoute: initialRoute,
            onGenerateInitialRoutes: (NavigatorState navigator, String initialRoute) {
              return generateInitialRoutes(
                navigator as ExtendedNavigatorState,
                initialRoute,
                initialRouteArgs,
              );
            },
            observers: [
              HeroController(createRectTween: _createRectTween),
              ...observers,
            ],
            key: key);

  final T router;
  final List<RouteGuard> guards;
  final String basePath;

  @override
  ExtendedNavigatorState createState() {
    return _NavigationStatesContainer._instance.create<T>();
  }

  static get _placeHolderRoute => PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 0),
        pageBuilder: (_, __, ___) => Container(color: Colors.green),
      );

  static List<Route<dynamic>> generateInitialRoutes(
    ExtendedNavigatorState navigator,
    String initialRouteName,
    Object initialRouteArgs,
  ) {
    var initialRoutes = <Route>[];
    var router = navigator.router;
    assert(router != null);
    assert(initialRouteName != null);

    var matcher = RouteMatcher.fromUri(Uri.parse(initialRouteName));
    var matches = router.allMatches(matcher);
//    var matches = matcher.allMatches(router.allRoutes).toList();
    for (var i = 0; i < matches.length; i++) {
      var match = matches[i];
      if (i == matches.length - 1) {
        if (match.hasRest) {
          match = match.copyWith(initialArgsToPass: initialRouteArgs);
        } else {
          match = match.copyWith(arguments: initialRouteArgs);
        }
      }
      if (navigator._guardedInitialRoutes.isNotEmpty || router._hasGuards(match.template)) {
        navigator._guardedInitialRoutes.add(match);
        if (match.template == Navigator.defaultRouteName) {
          initialRoutes.add(_placeHolderRoute);
        }
      } else {
        var route = navigator.widget.onGenerateRoute(match);
        initialRoutes.add(route);
      }
    }
    initialRoutes.removeWhere((route) => route == null);

    return initialRoutes;
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
        throw FlutterError('ExtendedNavigator operation requested with a context that does not include an ExtendedNavigator.\n'
            'The context used to push or pop routes from the ExtendedNavigator must be that of a '
            'widget that is a descendant of a ExtendedNavigator widget.');
      }
      return true;
    }());
    return navigator;
  }
}

class ExtendedNavigatorState<T extends RouterBase> extends NavigatorState with WidgetsBindingObserver {
//  final Map<String, List<Type>> _guardedRoutes;
  final _registeredGuards = <Type, RouteGuard>{};

  RouterBase _router;

  T get router => _router;

  String get basePath => widget.basePath ?? '';

  List<MatchResult> _guardedInitialRoutes = [];

  ExtendedNavigatorState get parent => _parent;
  ExtendedNavigatorState _parent;

  @override
  ExtendedNavigator get widget => super.widget as ExtendedNavigator;

  @override
  void initState() {
    _router = widget.router;
    assert(_router != null);
    widget.guards?.forEach(_registerGuard);
    super.initState();
    if (_guardedInitialRoutes.isNotEmpty) {
      _pushAllGuarded(_guardedInitialRoutes);
    }
  }

  Future<void> _pushAllGuarded(Iterable<MatchResult> matches) async {
    for (var match in matches) {
      print(match.template);
      if (await _canNavigate(match.template)) {
        var route = widget.onGenerateRoute(match);
        if (match.path == Navigator.defaultRouteName) {
          pushAndRemoveUntil(route, (route) => false);
        } else {
          push(route);
        }
        if (route.settings is _ParentRouteData) {
          break;
        }
      } else {
        break;
      }
    }
  }

  Future<void> pushDeepLink(String url, {Map<String, String> queryParams}) async {
    return root._pushDeepLink(Uri(path: url, queryParameters: queryParams));
  }

  Future<void> _pushDeepLink(Uri uri) async {
    var matcher = RouteMatcher.fromUri(uri);
    var matches = matcher.allMatches(router.allRoutes);
    return _pushAllGuarded(matches);
  }

  bool get isRoot => parent == null;
  WillPopCallback _willPopCallback;

  ExtendedNavigatorState get root => context.findRootAncestorStateOfType<ExtendedNavigatorState>() ?? this;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parent = context.findAncestorStateOfType<ExtendedNavigatorState>();
    if (isRoot) {
      WidgetsBinding.instance.addObserver(this);
    }
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
    _pushDeepLink(Uri.parse(route));
    return true;
  }

  Future<bool> canNavigate(String routeName) => _canNavigate(routeName);

  Future<bool> _canNavigate(String routeName, {Object arguments, OnNavigationRejected onReject}) async {
    var match = _router.findFullMatch(RouteSettings(name: routeName));
    if (match == null || !_router._hasGuards(match.template)) {
      return true;
    }

    for (Type guardType in _router.guardedRoutes[match.template]) {
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
    if (parent == null) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }
}

class _NavigationStatesContainer {
  // ensure we only have one instance of the container
  static final _NavigationStatesContainer _instance = _NavigationStatesContainer._();
  final Map<Type, ExtendedNavigatorState> _navigatorKeys = {};

  ExtendedNavigatorState operator [](Type type) => _navigatorKeys[type];

  _NavigationStatesContainer._();

  ExtendedNavigatorState create<T extends RouterBase>() {
    return _navigatorKeys[T] = ExtendedNavigatorState<T>();
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

class NestedNavigator extends StatelessWidget {
  const NestedNavigator({
    Key key,
    this.initialRoute,
    this.guards = const [],
    this.onUnknownRoute,
    this.observers = const <NavigatorObserver>[],
  }) : super(key: key);

  final String initialRoute;
  final List<RouteGuard> guards;
  final List<NavigatorObserver> observers;
  final RouteFactory onUnknownRoute;

  @override
  Widget build(BuildContext context) {
    var initial = initialRoute;
    var basePath = '';
    var parentData = _ParentRouteData.of(context);
    if (parentData != null) {
      basePath = parentData.path;
      if (parentData.initialRoute?.isNotEmpty == true) {
        initial = parentData.initialRoute;
      }
    } else {
      throw FlutterError('Router can not be null');
    }
    var parentNav = ExtendedNavigator.of(context).widget;
    return ExtendedNavigator(
      router: parentData.router,
      initialRoute: initial,
      basePath: basePath,
      onUnknownRoute: onUnknownRoute ?? parentNav.onUnknownRoute,
      guards: [
        ...guards,
        ...parentNav.guards,
      ],
      observers: [
//        ...parentNav.observers,
        ...observers,
      ],
      initialRouteArgs: parentData._initialArgsToPass,
      key: key,
    );
  }
}
