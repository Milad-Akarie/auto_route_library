import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/route_matcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
    this.guards = const [],
    String initialRoute,
    this.name,
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
  final String name;

  @override
  ExtendedNavigatorState createState() {
    return ExtendedNavigatorState<T>();
  }

  static get _placeHolderRoute => PageRouteBuilder(
        pageBuilder: (_, __, ___) => Container(color: Colors.white),
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

    if (!kIsWeb && initialRouteName.startsWith('/') && initialRouteName.length > 1) {
      initialRoutes.add(navigator.widget.onGenerateRoute(RouteSettings(name: '/')));
    }

    var settings = RouteSettings(name: initialRouteName, arguments: initialRouteArgs);
    var route = navigator.widget.onGenerateRoute(settings);
    if (route == null) {
      route = navigator.widget.onUnknownRoute(settings);
    }
    initialRoutes.add(route);

//    var matcher = RouteMatcher.fromUri(Uri.parse(initialRouteName));
//    var matches = router.allMatches(matcher);
//    for (var i = 0; i < matches.length; i++) {
//      var match = matches[i];
//      print(match.path);
//      if (i == matches.length - 1) {
//        if (match.hasRest) {
//          match = match.copyWith(initialArgsToPass: initialRouteArgs);
//        } else {
//          match = match.copyWith(arguments: initialRouteArgs);
//        }
//      }
//      if (navigator._guardedInitialRoutes.isNotEmpty || match.hasGuards) {
//        navigator._guardedInitialRoutes.add(match);
//        if (match.routeDef.template == Navigator.defaultRouteName) {
//          initialRoutes.add(_placeHolderRoute);
//        }
//      } else {
//        var route = navigator.widget.onGenerateRoute(match);
//        initialRoutes.add(route);
//      }
//    }

    initialRoutes.removeWhere((route) => route == null);
    return initialRoutes;
  }

  static TransitionBuilder builder({
    @required RouterBase router,
    String initialRoute,
    List<RouteGuard> guards,
  }) =>
      (_, widget) {
        assert(widget is Navigator);
        var navigator = widget as Navigator;
        return ExtendedNavigator(
          key: navigator.key,
          guards: guards,
          onUnknownRoute: navigator.onUnknownRoute,
          observers: navigator.observers,
          initialRoute: initialRoute,
          router: router,
        );
      };

  ExtendedNavigator call(_, navigator) => this;

  static ExtendedNavigatorState ofRouter<T extends RouterBase>() {
    assert(T != null);
    return _NavigationStatesContainer._instance.get<T>();
  }

  static ExtendedNavigatorState byName(String name) {
    assert(name != null);
    return _NavigationStatesContainer._instance.get(name);
  }

  static ExtendedNavigatorState get root => _NavigationStatesContainer._instance.getRootNavigator();

  @Deprecated("renamed to root")
  static ExtendedNavigatorState get rootNavigator => root;

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
            'ExtendedNavigator operation requested with a context that does not include an ExtendedNavigator.\n'
            'The context used to push or pop routes from the ExtendedNavigator must be that of a '
            'widget that is a descendant of a ExtendedNavigator widget.');
      }
      return true;
    }());
    return navigator;
  }
}

class ExtendedNavigatorState<T extends RouterBase> extends NavigatorState {
  final _registeredGuards = <Type, RouteGuard>{};
  RouterBase _router;

  T get router => _router;

  List<RouteMatch> _guardedInitialRoutes = [];

  ExtendedNavigatorState get parent => _parent;

  ExtendedNavigatorState _parent;
  final children = <ExtendedNavigatorState>[];

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

  Future<void> _pushAllGuarded(Iterable<RouteMatch> matches) async {
    for (var match in matches) {
      if (await _canNavigate(match.template)) {
        var route = widget.onGenerateRoute(match);

        if (match.template == Navigator.defaultRouteName) {
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

  bool get isRoot => parent == null;

  WillPopCallback _willPopCallback;

  ExtendedNavigatorState get root => context.findRootAncestorStateOfType<ExtendedNavigatorState>() ?? this;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parent = context.findAncestorStateOfType<ExtendedNavigatorState>();
    if (_parent != null) {
      _parent.children.add(this);
    }

    _NavigationStatesContainer._instance.register(this, name: widget.name);
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

  @optionalTypeArgs
  Future<T> pushNamedAndRemoveUntilPath<T extends Object>(
    String newRouteName,
    String anchorPath, {
    Object arguments,
    OnNavigationRejected onReject,
  }) async {
    return await _canNavigate(newRouteName, arguments: arguments, onReject: onReject)
        ? super.pushNamedAndRemoveUntil<T>(
            newRouteName,
            RouteData.withPath(anchorPath),
            arguments: arguments,
          )
        : null;
  }

  void popUntilPath(String path) {
    popUntil(RouteData.withPath(path));
  }

  void popUntilRoot() {
    popUntil((route) => route.isFirst);
  }

  Future<bool> canNavigate(String routeName) => _canNavigate(routeName);

  Future<bool> _canNavigate(String routeName, {Object arguments, OnNavigationRejected onReject}) async {
    var match = _router.findMatch(RouteSettings(name: routeName));
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
    if (_parent != null) {
      _parent.children.remove(this);
    }
    super.dispose();
  }
}

class _NavigationStatesContainer {
  // ensure we only have one instance of the container
  static final _NavigationStatesContainer _instance = _NavigationStatesContainer._();
  final Map<String, ExtendedNavigatorState> _navigators = {};

  ExtendedNavigatorState operator [](Type type) => _navigators[type];

  _NavigationStatesContainer._();

  void register(ExtendedNavigatorState navigatorState, {String name}) {
    _navigators[name ?? navigatorState._router.runtimeType.toString()] = navigatorState;
  }

  ExtendedNavigatorState getRootNavigator() {
    if (_navigators.isNotEmpty) {
      return _navigators.values.first.root;
    }
    return null;
  }

  ExtendedNavigatorState remove<T extends RouterBase>() {
    return _navigators.remove(T.toString());
  }

  ExtendedNavigatorState get<T extends RouterBase>([String name]) {
    return _navigators[name ?? T.toString()];
  }
}

class NestedNavigator extends StatelessWidget {
  const NestedNavigator({
    Key key,
    this.initialRoute,
    this.guards = const [],
    this.onUnknownRoute,
    this.name,
    this.observers = const <NavigatorObserver>[],
  }) : super(key: key);

  final String initialRoute;
  final List<RouteGuard> guards;
  final List<NavigatorObserver> observers;
  final RouteFactory onUnknownRoute;
  final String name;

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
      name: name,
      initialRoute: initial,
      basePath: basePath,
      onUnknownRoute: onUnknownRoute ?? parentNav.onUnknownRoute,
      guards: [
        ...guards,
        if (parentNav.guards != null) ...parentNav.guards,
      ],
      observers: observers,
      initialRouteArgs: parentData._initialArgsToPass,
      key: key,
    );
  }
}
