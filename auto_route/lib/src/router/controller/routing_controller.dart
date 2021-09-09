import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/matcher/route_matcher.dart';
import 'package:auto_route/src/navigation_failure.dart';
import 'package:auto_route/src/route/page_route_info.dart';
import 'package:auto_route/src/route/route_data_scope.dart';
import 'package:auto_route/src/router/auto_route_page.dart';
import 'package:collection/collection.dart' show ListEquality;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

import '../../utils.dart';

part '../../route/route_data.dart';

typedef RouteDataPredicate = bool Function(RouteData route);
typedef OnNestedNavigateCallBack = void Function(
    List<RouteMatch> routes, bool initial);
typedef OnTabNavigateCallBack = void Function(RouteMatch route, bool initial);

abstract class RoutingController with ChangeNotifier {
  final Map<LocalKey, RoutingController> _childControllers = {};
  final List<AutoRoutePage> _pages = [];

  void attachChildController(RoutingController childController) {
    _childControllers[childController.routeData.key] = childController;
  }

  void removeChildController(RoutingController childController) {
    _childControllers.remove(childController.routeData.key);
  }

  List<RouteData> get stackData =>
      List.unmodifiable(_pages.map((e) => e.routeData));

  bool isRouteActive(String routeName) {
    return root._isRouteActive(routeName);
  }

  bool _isRouteActive(String routeName) {
    return currentSegments.any(
      (r) => r.routeName == routeName,
    );
  }

  RouteData _createRouteData(RouteMatch route, RouteData parent) {
    return RouteData(
      route: route,
      router: this,
      parent: parent,
      preMatchedPendingRoutes: route.children,
    );
  }

  RouteMatch? _matchOrReportFailure(
    PageRouteInfo route, [
    OnNavigationFailure? onFailure,
  ]) {
    var match = matcher.matchByRoute(route);
    if (match != null) {
      return match;
    } else {
      if (onFailure != null) {
        onFailure(RouteNotFoundFailure(route));
        return null;
      } else {
        throw FlutterError(
            "[${toString()}] Router can not navigate to ${route.fullPath}");
      }
    }
  }

  List<RouteMatch>? _matchAllOrReportFailure(
    List<PageRouteInfo> routes, [
    OnNavigationFailure? onFailure,
  ]) {
    final matches = <RouteMatch>[];
    for (var route in routes) {
      var match = _matchOrReportFailure(route, onFailure);
      if (match != null) {
        matches.add(match);
      } else {
        return null;
      }
    }
    return matches;
  }

  bool get managedByWidget;

  bool isPathActive(String path) {
    return root._isPathActive(path);
  }

  bool _isPathActive(String pattern) {
    return RegExp(pattern)
        .hasMatch(p.joinAll(currentSegments.map((e) => e.stringMatch)));
  }

  bool _canHandleNavigation(PageRouteInfo route) {
    return routeCollection.containsKey(route.routeName);
  }

  _RouterScopeResult<T>?
      _findPathScopeOrReportFailure<T extends RoutingController>(String path,
          {bool includePrefixMatches = false, OnNavigationFailure? onFailure}) {
    final routers = [
      if (this is T) this as T,
      ..._getAncestors().whereType<T>()
    ];
    for (var router in routers) {
      final matches = router.matcher.match(
        path,
        includePrefixMatches: includePrefixMatches,
      );
      if (matches != null) {
        return _RouterScopeResult<T>(router, matches);
      }
    }
    if (onFailure != null) {
      onFailure(
        RouteNotFoundFailure(
          PageRouteInfo('', path: path),
        ),
      );
    } else {
      throw FlutterError('Can not navigate to $path');
    }
    return null;
  }

  RoutingController _findScope<T extends RoutingController>(
      PageRouteInfo route) {
    if (_parent == null || _canHandleNavigation(route)) {
      return this;
    }
    final routers = [this, ..._getAncestors()];
    return routers.firstWhere((r) => r._canHandleNavigation(route),
        orElse: () => this);
  }

  Future<dynamic> navigate(PageRouteInfo route,
      {OnNavigationFailure? onFailure}) async {
    return _findScope(route)._navigate(route, onFailure: onFailure);
  }

  Future<dynamic> _navigate(PageRouteInfo route,
      {OnNavigationFailure? onFailure}) async {
    final match = _matchOrReportFailure(route, onFailure);
    if (match != null) {
      return _navigateAll([match], onFailure: onFailure);
    } else {
      return SynchronousFuture(null);
    }
  }

  Future<void> navigateNamed(
    String path, {
    bool includePrefixMatches = false,
    OnNavigationFailure? onFailure,
  }) {
    final scope = _findPathScopeOrReportFailure<RoutingController>(
      path,
      includePrefixMatches: includePrefixMatches,
      onFailure: onFailure,
    );
    if (scope != null) {
      return scope.router._navigateAll(
        scope.matches,
      );
    }
    return SynchronousFuture(null);
  }

  List<RoutingController> _getAncestors() {
    void collectRouters(
        RoutingController currentParent, List<RoutingController> all) {
      all.add(currentParent);
      if (currentParent._parent != null) {
        collectRouters(currentParent._parent!, all);
      }
    }

    final routers = <RoutingController>[];
    if (_parent != null) {
      collectRouters(_parent!, routers);
    }
    return routers;
  }

  // should find a way to avoid this
  void _updateSharedPathData({
    Map<String, dynamic> queryParams = const {},
    String fragment = '',
    bool includeAncestors = false,
  });

  int get currentSegmentsHash => const ListEquality().hash(currentSegments);

  LocalKey get key;

  RouteMatcher get matcher;

  List<AutoRoutePage> get stack;

  RoutingController? get _parent;

  T? parent<T extends RoutingController>() {
    return _parent == null ? null : _parent as T;
  }

  StackRouter get root => (_parent?.root ?? this) as StackRouter;

  StackRouter? get parentAsStackRouter => parent<StackRouter>();

  bool get isRoot => _parent == null;

  RoutingController get topMost;

  RouteData? get currentChild;

  RouteData get current;

  RouteData get topRoute => topMost.current;

  RouteData get routeData;

  RouteCollection get routeCollection;

  bool get hasEntries;

  T? innerRouterOf<T extends RoutingController>(String routeName) {
    if (_childControllers.isEmpty) {
      return null;
    }
    return _childControllers.values.whereType<T>().lastOrNull(
          ((c) => c.routeData.name == routeName),
        );
  }

  List<RouteMatch>? get initialPreMatchedRoutes;

  PageBuilder get pageBuilder;

  @optionalTypeArgs
  Future<bool> pop<T extends Object?>([T? result]);

  @optionalTypeArgs
  Future<bool> popTop<T extends Object?>([T? result]) => topMost.pop<T>(result);

  bool get canPopSelfOrChildren;

  List<RouteMatch> get currentSegments;

  @override
  String toString() => '${routeData.name} Router';

  Future<void> _navigateAll(List<RouteMatch> routes,
      {OnNavigationFailure? onFailure});
}

class TabsRouter extends RoutingController {
  final RoutingController? _parent;
  final LocalKey key;
  final RouteCollection routeCollection;
  final PageBuilder pageBuilder;
  final RouteMatcher matcher;
  final RouteData routeData;
  final List<RouteMatch>? initialPreMatchedRoutes;
  int _activeIndex = 0;
  bool managedByWidget;
  OnTabNavigateCallBack? onNavigate;

  TabsRouter(
      {required this.routeCollection,
      required this.pageBuilder,
      required this.key,
      required this.routeData,
      this.managedByWidget = false,
      this.onNavigate,
      RoutingController? parent,
      this.initialPreMatchedRoutes,
      int? initialIndex})
      : matcher = RouteMatcher(routeCollection),
        _activeIndex = initialIndex ?? 0,
        _parent = parent {
    if (parent != null) {
      addListener(root.notifyListeners);
    }
  }

  RouteData get current {
    return currentChild ?? routeData;
  }

  RouteData? get currentChild {
    if (_activeIndex < _pages.length) {
      return _pages[_activeIndex].routeData;
    } else {
      return null;
    }
  }

  int get activeIndex => _activeIndex;

  void setActiveIndex(int index, {bool notify = true}) {
    assert(index >= 0 && index < _pages.length);
    if (_activeIndex != index) {
      _activeIndex = index;
      if (notify) {
        notifyListeners();
      }
    }
  }

  @override
  List<AutoRoutePage> get stack => List.unmodifiable(_pages);

  AutoRoutePage? get _activePage {
    return _pages.isEmpty ? null : _pages[_activeIndex];
  }

  @override
  RoutingController get topMost {
    var activeKey = _activePage?.routeData.key;
    if (_childControllers.containsKey(activeKey)) {
      return _childControllers[activeKey]!.topMost;
    }
    return this;
  }

  @override
  bool get hasEntries => _pages.isNotEmpty;

  @override
  @optionalTypeArgs
  Future<bool> pop<T extends Object?>([T? result]) {
    if (_parent != null) {
      return _parent!.pop<T>(result);
    } else {
      return SynchronousFuture<bool>(false);
    }
  }

  void setupRoutes(List<PageRouteInfo> routes) {
    final routesToPush = _matchAllOrReportFailure(routes)!;
    if (initialPreMatchedRoutes?.isNotEmpty == true) {
      final preMatchedRoute = initialPreMatchedRoutes!.last;
      final correspondingRouteIndex = routes.indexWhere(
        (r) => r.routeName == preMatchedRoute.routeName,
      );
      if (correspondingRouteIndex != -1) {
        if (managedByWidget) {
          onNavigate?.call(preMatchedRoute, true);
        }
        routesToPush[correspondingRouteIndex] = preMatchedRoute;
        _activeIndex = correspondingRouteIndex;
      }
    }
    if (routesToPush.isNotEmpty) {
      _pushAll(routesToPush);
    }
  }

  void _pushAll(List<RouteMatch> routes) {
    for (var route in routes) {
      var data = _createRouteData(route, routeData);
      _pages.add(pageBuilder(data));
    }
  }

  void replaceAll(List<PageRouteInfo> routes) {
    final routesToPush = _matchAllOrReportFailure(routes)!;
    _pages.clear();
    _pushAll(routesToPush);
  }

  @override
  Future<void> _navigateAll(List<RouteMatch> routes,
      {OnNavigationFailure? onFailure}) async {
    if (routes.isNotEmpty) {
      final mayUpdateRoute = routes.last;

      final pageToUpdateIndex = _pages.indexWhere(
        (p) => p.routeKey == mayUpdateRoute.key,
      );

      if (pageToUpdateIndex != -1) {
        if (!managedByWidget) {
          setActiveIndex(pageToUpdateIndex);
        } else if (onNavigate != null) {
          onNavigate!(mayUpdateRoute, false);
        }
        var mayUpdateController = _childControllers[mayUpdateRoute.key];

        if (mayUpdateController != null) {
          final newRoutes = mayUpdateRoute.children ?? const [];
          if (mayUpdateController.managedByWidget) {
            if (mayUpdateController is StackRouter) {
              mayUpdateController.onNavigate?.call(newRoutes, false);
            } else if (mayUpdateController is TabsRouter &&
                newRoutes.isNotEmpty) {
              mayUpdateController.onNavigate?.call(newRoutes.last, false);
            }
          }
          return mayUpdateController._navigateAll(newRoutes,
              onFailure: onFailure);
        } else {
          final data = _createRouteData(mayUpdateRoute, routeData);
          _pages[pageToUpdateIndex] = pageBuilder(data);
        }
      }
      _updateSharedPathData(
        queryParams: mayUpdateRoute.queryParams.rawMap,
        fragment: mayUpdateRoute.fragment,
        includeAncestors: false,
      );
    }

    return SynchronousFuture(null);
  }

  StackRouter? stackRouterOfIndex(int index) {
    if (_childControllers.isEmpty) {
      return null;
    }
    final routeKey = _pages[index].routeData.key;
    if (_childControllers[routeKey] is StackRouter) {
      return _childControllers[routeKey] as StackRouter;
    } else {
      return null;
    }
  }

  @override
  bool get canPopSelfOrChildren {
    if (_childControllers.containsKey(_pages[_activeIndex].routeData.key)) {
      return _childControllers[_pages[_activeIndex].routeData.key]!
          .canPopSelfOrChildren;
    }
    return false;
  }

  @override
  List<RouteMatch> get currentSegments {
    var currentData = currentChild;
    final segments = <RouteMatch>[];
    if (currentData != null) {
      segments.add(currentData.route);
      if (_childControllers.containsKey(currentData.key)) {
        segments.addAll(
          _childControllers[currentData.key]!.currentSegments,
        );
      }
    } else if (routeData.route.hasChildren) {
      segments.addAll(
        routeData.route.children!.last.flattened,
      );
    }
    return segments;
  }

  @override
  void _updateSharedPathData({
    Map<String, dynamic> queryParams = const {},
    String fragment = '',
    bool includeAncestors = false,
  }) {
    final newData = _pages[activeIndex].routeData;
    final route = newData.route;
    newData._updateRoute(route.copyWith(
      queryParams: Parameters(queryParams),
      fragment: fragment,
    ));
    if (includeAncestors && _parent != null) {
      _parent!
          ._updateSharedPathData(queryParams: queryParams, fragment: fragment);
    }
  }
}

abstract class StackRouter extends RoutingController {
  final RoutingController? _parent;
  final LocalKey key;
  final GlobalKey<NavigatorState> _navigatorKey;
  final List<RouteMatch>? initialPreMatchedRoutes;
  final OnNestedNavigateCallBack? onNavigate;

  StackRouter({
    required this.key,
    this.onNavigate,
    RoutingController? parent,
    GlobalKey<NavigatorState>? navigatorKey,
    this.initialPreMatchedRoutes,
  })  : _navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>(),
        _parent = parent {
    if (parent != null) {
      addListener(root.notifyListeners);
    }
  }

  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  RouteCollection get routeCollection;

  PageBuilder get pageBuilder;

  RouteMatcher get matcher;

  @override
  List<RouteMatch> get currentSegments {
    var currentData = currentChild;
    final segments = <RouteMatch>[];
    if (currentData != null) {
      segments.add(currentData.route);
      if (_childControllers.containsKey(currentData.key)) {
        segments.addAll(
          _childControllers[currentData.key]!.currentSegments,
        );
      }
    } else if (routeData.route.hasChildren) {
      segments.addAll(
        routeData.route.children!.last.flattened,
      );
    }
    return segments;
  }

  @override
  bool get canPopSelfOrChildren {
    if (_pages.length > 1) {
      return true;
    } else if (_pages.isNotEmpty &&
        _childControllers.containsKey(_pages.last.routeData.key)) {
      return _childControllers[_pages.last.routeData.key]!.canPopSelfOrChildren;
    }
    return false;
  }

  @override
  RouteData get current {
    return currentChild ?? routeData;
  }

  @override
  RouteData? get currentChild {
    if (_pages.isNotEmpty) {
      return _pages.last.routeData;
    }
    return null;
  }

  @override
  RoutingController get topMost {
    if (_childControllers.isNotEmpty) {
      var topRouteKey = _pages.last.routeData.key;
      if (_childControllers.containsKey(topRouteKey)) {
        return _childControllers[topRouteKey]!.topMost;
      }
    }
    return this;
  }

  void _updateSharedPathData({
    Map<String, dynamic> queryParams = const {},
    String fragment = '',
    bool includeAncestors = false,
  }) {
    for (var index = 0; index < _pages.length; index++) {
      final data = _pages[index].routeData;
      final route = data.route;
      data._updateRoute(route.copyWith(
        queryParams: Parameters(queryParams),
        fragment: fragment,
      ));
    }
    if (includeAncestors && _parent != null) {
      _parent!._updateSharedPathData(
        queryParams: queryParams,
        fragment: fragment,
        includeAncestors: includeAncestors,
      );
    }
  }

  @override
  @optionalTypeArgs
  Future<bool> pop<T extends Object?>([T? result]) async {
    final NavigatorState? navigator = _navigatorKey.currentState;
    if (navigator == null) return SynchronousFuture<bool>(false);
    if (await navigator.maybePop<T>(result)) {
      return true;
    } else if (_parent != null) {
      return _parent!.pop<T>(result);
    } else {
      return false;
    }
  }

  @optionalTypeArgs
  void popForced<T extends Object?>([T? result]) {
    final NavigatorState? navigator = _navigatorKey.currentState;
    if (navigator != null) {
      navigator.pop(result);
    }
  }

  bool removeLast() => _removeLast();

  void removeRoute(RouteData route, {bool notify = true}) {
    var pageIndex = _pages.lastIndexWhere((p) => p.routeKey == route.key);
    if (pageIndex != -1) {
      _pages.removeAt(pageIndex);
    }
    _updateSharedPathData(includeAncestors: true);
    if (_childControllers.containsKey(route.key)) {
      _childControllers.remove(route.key);
    }
    if (notify) {
      notifyListeners();
    }
  }

  bool _removeLast({bool notify = true}) {
    var didRemove = false;
    if (_pages.isNotEmpty) {
      removeRoute(_pages.last.routeData);
      if (notify) {
        notifyListeners();
      }
      didRemove = true;
    }
    return didRemove;
  }

  @override
  List<AutoRoutePage> get stack => List.unmodifiable(_pages);

  @optionalTypeArgs
  Future<T?> push<T extends Object?>(PageRouteInfo route,
      {OnNavigationFailure? onFailure}) async {
    return _findStackScope(route)._push<T>(route, onFailure: onFailure);
  }

  StackRouter _findStackScope(PageRouteInfo route) {
    if (_parent == null || _canHandleNavigation(route)) {
      return this;
    }
    final stackRouters = _getAncestors().whereType<StackRouter>();
    return stackRouters.firstWhere(
      (c) => c._canHandleNavigation(route),
      orElse: () => this,
    );
  }

  Future<dynamic> _popUntilOrPushAll(List<RouteMatch> routes,
      {OnNavigationFailure? onFailure}) async {
    final anchor = routes.first;
    final anchorPage = _pages.lastOrNull(
      (p) => p.routeKey == anchor.key,
    );
    if (anchorPage != null) {
      for (var candidate in List<AutoRoutePage>.unmodifiable(_pages).reversed) {
        _pages.removeLast();
        if (candidate.routeKey == anchorPage.routeKey) {
          break;
        } else {
          if (_childControllers.containsKey(candidate.routeKey)) {
            _childControllers.remove(candidate.routeKey);
          }
        }
      }
    }
    return _pushAllGuarded(
      routes,
      onFailure: onFailure,
      updateAncestorsPathData: false,
      returnLastRouteCompleter: false,
    );
  }

  @optionalTypeArgs
  Future<T?> _push<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
    bool notify = true,
  }) async {
    assert(
      !managedByWidget,
      'Pages stack can be managed by either the Widget (AutoRouter.declarative) or the (StackRouter)',
    );
    var match = _matchOrReportFailure(route, onFailure);
    if (match == null) {
      return null;
    }
    if (await _canNavigate(match, onFailure)) {
      _updateSharedPathData(
        queryParams: route.rawQueryParams,
        fragment: route.fragment,
        includeAncestors: true,
      );
      return _addEntry<T>(match, notify: notify);
    }
    return null;
  }

  @optionalTypeArgs
  Future<T?> replace<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) {
    final scope = _findStackScope(route);
    scope.removeLast();
    return scope._push<T>(route, onFailure: onFailure);
  }

  Future<void> pushAll(
    List<PageRouteInfo> routes, {
    OnNavigationFailure? onFailure,
  }) {
    assert(routes.isNotEmpty);
    return _findStackScope(routes.first)._pushAll(
      routes,
      onFailure: onFailure,
      notify: true,
    );
  }

  Future<void> popAndPushAll(List<PageRouteInfo> routes, {onFailure}) {
    assert(routes.isNotEmpty);
    final scope = _findStackScope(routes.first);
    scope.pop();
    return scope._pushAll(routes, onFailure: onFailure, notify: true);
  }

  Future<void> replaceAll(
    List<PageRouteInfo> routes, {
    OnNavigationFailure? onFailure,
  }) {
    final scope = _findStackScope(routes.first);
    scope._pages.clear();
    return scope._pushAll(routes, onFailure: onFailure);
  }

  void popUntilRoot() {
    assert(_navigatorKey.currentState != null);
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  @optionalTypeArgs
  Future<T?> popAndPush<T extends Object?, TO extends Object?>(
    PageRouteInfo route, {
    TO? result,
    OnNavigationFailure? onFailure,
  }) {
    final scope = _findStackScope(route);
    scope.pop<TO>(result);
    return scope._push<T>(route, onFailure: onFailure);
  }

  bool removeUntil(RouteDataPredicate predicate) => _removeUntil(predicate);

  void popUntil(RoutePredicate predicate) {
    _navigatorKey.currentState?.popUntil(predicate);
  }

  bool _removeUntil(RouteDataPredicate predicate, {bool notify = true}) {
    var didRemove = false;
    for (var candidate in List.unmodifiable(_pages).reversed) {
      if (predicate(candidate.routeData)) {
        break;
      } else {
        _removeLast(notify: false);
        didRemove = true;
      }
    }
    if (didRemove && notify) {
      notifyListeners();
    }
    return didRemove;
  }

  bool removeWhere(RouteDataPredicate predicate) {
    var didRemove = false;
    for (var entry in List.unmodifiable(_pages)) {
      if (predicate(entry.routeData)) {
        didRemove = true;
        _pages.remove(entry);
      }
    }
    notifyListeners();
    return didRemove;
  }

  void updateDeclarativeRoutes(List<PageRouteInfo> routes) async {
    _pages.clear();
    for (var route in routes) {
      var match = _matchOrReportFailure(route);
      if (match == null) {
        break;
      }
      if (!listNullOrEmpty(match.guards)) {
        throw FlutterError("Declarative routes can not have guards");
      }
      final data = _createRouteData(match, routeData);
      _pages.add(pageBuilder(data));
    }
  }

  Future<void> _pushAll(
    List<PageRouteInfo> routes, {
    OnNavigationFailure? onFailure,
    bool notify = true,
  }) async {
    final matches = _matchAllOrReportFailure(routes, onFailure);
    if (matches != null) {
      _pushAllGuarded(matches, onFailure: onFailure, notify: notify);
    }
    return SynchronousFuture(null);
  }

  @optionalTypeArgs
  Future<T?> _pushAllGuarded<T extends Object?>(
    List<RouteMatch> routes, {
    OnNavigationFailure? onFailure,
    bool notify = true,
    bool updateAncestorsPathData = true,
    bool returnLastRouteCompleter = true,
  }) async {
    assert(
      !managedByWidget,
      'Pages stack can be managed by either the Widget (AutoRouter.declarative) or Router',
    );

    for (var i = 0; i < routes.length; i++) {
      var route = routes[i];
      if (await _canNavigate(
        route,
        onFailure,
        pendingRoutes: routes.toList()..removeAt(i),
      )) {
        if (i != routes.length - 1) {
          _addEntry(route, notify: false);
        } else {
          _updateSharedPathData(
            queryParams: route.queryParams.rawMap,
            fragment: route.fragment,
            includeAncestors: updateAncestorsPathData,
          );
          var completer = _addEntry<T>(route, notify: true);
          if (returnLastRouteCompleter) {
            return completer;
          }
        }
      } else {
        break;
      }
    }
    if (notify) {
      notifyListeners();
    }
    return SynchronousFuture(null);
  }

  Future<T?> _addEntry<T extends Object?>(
    RouteMatch route, {
    bool notify = true,
  }) {
    final data = _createRouteData(route, routeData);
    final page = pageBuilder(data);
    _pages.add(page);
    if (notify) {
      notifyListeners();
    }
    return (page as AutoRoutePage<T>).popped;
  }

  Future<bool> _canNavigate(
    RouteMatch route,
    OnNavigationFailure? onFailure, {
    List<RouteMatch> pendingRoutes = const [],
  }) async {
    if (route.guards.isEmpty) {
      return true;
    }
    for (var guard in route.guards) {
      final completer = Completer<bool>();
      guard.onNavigation(
          NavigationResolver(
            completer,
            route,
            pendingRoutes: pendingRoutes,
          ),
          this);
      if (!await completer.future) {
        if (onFailure != null) {
          onFailure(RejectedByGuardFailure(route, guard));
        }
        return false;
      }
    }
    return true;
  }

  Future<void> navigateAll(
    List<RouteMatch> routes, {
    OnNavigationFailure? onFailure,
  }) {
    return _navigateAll(routes, onFailure: onFailure);
  }

  @override
  Future<void> _navigateAll(
    List<RouteMatch> routes, {
    OnNavigationFailure? onFailure,
  }) async {
    if (routes.isNotEmpty) {
      if (!managedByWidget) {
        await _popUntilOrPushAll(routes, onFailure: onFailure);
      }
      final mayUpdateRoute = routes.last;
      final mayUpdateController = _childControllers[mayUpdateRoute.key];

      if (mayUpdateController != null) {
        final newChildren = mayUpdateRoute.children ?? const [];
        if (mayUpdateController.managedByWidget) {
          if (mayUpdateController is StackRouter) {
            mayUpdateController.onNavigate?.call(newChildren, false);
          } else if (mayUpdateController is TabsRouter &&
              newChildren.isNotEmpty) {
            mayUpdateController.onNavigate?.call(newChildren.last, false);
          }
        }
        return mayUpdateController._navigateAll(
          newChildren,
          onFailure: onFailure,
        );
      }
    } else if (!managedByWidget) {
      _reset();
    }
    return SynchronousFuture(null);
  }

  void _reset() {
    _pages.clear();
    _childControllers.clear();
  }

  @optionalTypeArgs
  Future<T?> pushAndPopUntil<T extends Object?>(
    PageRouteInfo route, {
    required RoutePredicate predicate,
    OnNavigationFailure? onFailure,
  }) {
    final scope = _findStackScope(route);
    scope.popUntil(predicate);
    return scope._push<T>(route, onFailure: onFailure);
  }

  @optionalTypeArgs
  Future<T?> replaceNamed<T extends Object?>(
    String path, {
    bool includePrefixMatches = false,
    OnNavigationFailure? onFailure,
  }) {
    final scope = _findPathScopeOrReportFailure<StackRouter>(
      path,
      includePrefixMatches: includePrefixMatches,
      onFailure: onFailure,
    );
    if (scope != null) {
      scope.router.removeLast();
      return scope.router._pushAllGuarded(
        scope.matches,
        onFailure: onFailure,
      );
    }
    return SynchronousFuture(null);
  }

  @optionalTypeArgs
  Future<T?> pushNamed<T extends Object?>(
    String path, {
    bool includePrefixMatches = false,
    OnNavigationFailure? onFailure,
  }) {
    final scope = _findPathScopeOrReportFailure<StackRouter>(
      path,
      includePrefixMatches: includePrefixMatches,
      onFailure: onFailure,
    );
    if (scope != null) {
      return scope.router._pushAllGuarded(
        scope.matches,
        onFailure: onFailure,
      );
    }
    return SynchronousFuture(null);
  }

  void popUntilRouteWithName(String name) {
    popUntil(ModalRoute.withName(name));
  }

  @override
  bool get hasEntries => _pages.isNotEmpty;
}

class NestedStackRouter extends StackRouter {
  final RouteMatcher matcher;
  final RouteCollection routeCollection;
  final PageBuilder pageBuilder;
  final bool managedByWidget;
  @override
  final RouteData routeData;

  NestedStackRouter({
    required this.routeCollection,
    required this.pageBuilder,
    required LocalKey key,
    required this.routeData,
    this.managedByWidget = false,
    required RoutingController parent,
    OnNestedNavigateCallBack? onRoutes,
    List<RouteMatch>? preMatchedRoutes,
    GlobalKey<NavigatorState>? navigatorKey,
  })  : matcher = RouteMatcher(routeCollection),
        super(
          key: key,
          initialPreMatchedRoutes: preMatchedRoutes,
          parent: parent,
          onNavigate: onRoutes,
          navigatorKey: navigatorKey,
        ) {
    _pushInitialRoutes();
  }

  void _pushInitialRoutes() {
    if (initialPreMatchedRoutes?.isNotEmpty == true) {
      if (managedByWidget) {
        onNavigate?.call(initialPreMatchedRoutes!, true);
      } else {
        _pushAllGuarded(initialPreMatchedRoutes!);
      }
    }
  }
}

class _RouterScopeResult<T extends RoutingController> {
  final T router;
  final List<RouteMatch> matches;

  const _RouterScopeResult(this.router, this.matches);
}
