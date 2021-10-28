import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/matcher/route_matcher.dart';
import 'package:auto_route/src/navigation_failure.dart';
import 'package:auto_route/src/route/page_route_info.dart';
import 'package:auto_route/src/route/route_data_scope.dart';
import 'package:auto_route/src/router/auto_route_page.dart';
import 'package:auto_route/src/router/controller/pageless_routes_observer.dart';
import 'package:auto_route/src/router/transitions/custom_page_route.dart';
import 'package:collection/collection.dart' show ListEquality;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

import '../../utils.dart';
import 'navigation_history.dart';

part '../../route/route_data.dart';
part 'auto_route_guard.dart';

typedef RouteDataPredicate = bool Function(RouteData route);
typedef OnNestedNavigateCallBack = void Function(
  List<RouteMatch> routes,
  bool initial,
);
typedef OnTabNavigateCallBack = void Function(RouteMatch route, bool initial);

abstract class RoutingController with ChangeNotifier {
  final Map<LocalKey, RoutingController> childControllers = {};
  final List<AutoRoutePage> _pages = [];

  void attachChildController(RoutingController childController) {
    childControllers[childController.routeData.key] = childController;
  }

  void removeChildController(RoutingController childController) {
    // childController must have the same key and  instance
    if (childController == childControllers[childController.key]) {
      childControllers.remove(childController.key);
    }
  }

  List<RouteData> get stackData =>
      List.unmodifiable(_pages.map((e) => e.routeData));

  bool isRouteActive(String routeName) {
    return root._isRouteActive(routeName);
  }

  bool _isRouteActive(String routeName) {
    return currentSegments.any(
      (r) => r.name == routeName,
    );
  }

  RouteData _createRouteData(RouteMatch route, RouteData parent) {
    final routeData = RouteData(
      route: route,
      router: this,
      parent: parent,
      pendingChildren: route.children ?? [],
    );

    final mayUpdateController = childControllers[routeData.key];
    if (mayUpdateController != null) {
      mayUpdateController._updateRouteDate(routeData);
    }

    return routeData;
  }

  RouteMatch? _matchOrReportFailure(
    PageRouteInfo route, [
    OnNavigationFailure? onFailure,
  ]) {
    final match = matcher.matchByRoute(route);
    if (match != null) {
      return match;
    } else {
      if (onFailure != null) {
        onFailure(RouteNotFoundFailure(route));
        return null;
      } else {
        final path = routeCollection.findPathTo(route.routeName);
        throw FlutterError(
          "\nLooks like you're trying to navigate to a nested route without adding their parent to stack first \n"
          "try navigating to ${path.map((e) => e.name).reduce((a, b) => a += ' -> $b')}",
        );
      }
    }
  }

  List<RouteMatch>? _matchAllOrReportFailure(
    List<PageRouteInfo> routes, [
    OnNavigationFailure? onFailure,
  ]) {
    final matches = <RouteMatch>[];
    for (final route in routes) {
      final match = _matchOrReportFailure(route, onFailure);
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
      _findPathScopeOrReportFailure<T extends RoutingController>(
    String path, {
    bool includePrefixMatches = false,
    OnNavigationFailure? onFailure,
  }) {
    final routers = topMostRouter(ignorePagelessRoutes: true)
        ._buildRoutersHierarchy()
        .whereType<T>();

    for (final router in routers) {
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
    PageRouteInfo route,
  ) {
    return topMostRouter(ignorePagelessRoutes: true)
        ._buildRoutersHierarchy()
        .firstWhere(
          (r) => r._canHandleNavigation(route),
          orElse: () => this,
        );
  }

  Future<dynamic> navigate(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) async {
    return _findScope(route)._navigate(route, onFailure: onFailure);
  }

  void _onNavigate(List<RouteMatch> routes, bool initial);

  Future<dynamic> _navigate(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) async {
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

  List<RoutingController> _buildRoutersHierarchy() {
    void collectRouters(
      RoutingController currentParent,
      List<RoutingController> all,
    ) {
      all.add(currentParent);
      if (currentParent._parent != null) {
        collectRouters(currentParent._parent!, all);
      }
    }

    final routers = <RoutingController>[this];
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

  int get stateHash => const ListEquality().hash(currentSegments);

  LocalKey get key;

  RouteMatcher get matcher;

  List<AutoRoutePage> get stack;

  RoutingController? get _parent;

  bool get isTopMost => this == topMostRouter();

  T? parent<T extends RoutingController>() {
    return _parent == null ? null : _parent! as T;
  }

  bool get canNavigateBack => navigationHistory.canNavigateBack;

  bool navigateBack() {
    if (canNavigateBack) {
      navigationHistory.removeLast();
      root._navigateAll([navigationHistory.currentEntry]);
      return true;
    }
    return false;
  }

  NavigationHistory get navigationHistory;

  StackRouter get root => (_parent?.root ?? this) as StackRouter;

  StackRouter? get parentAsStackRouter => parent<StackRouter>();

  bool get isRoot => _parent == null;

  @Deprecated('use topMostRouter() instead')
  RoutingController get topMost;

  RoutingController topMostRouter({bool ignorePagelessRoutes = false});

  RouteData? get currentChild;

  RouteData get current;

  RouteData get topRoute => topMostRouter().current;

  RouteMatch get topMatch => topRoute.topMatch;

  RouteData get routeData;

  void _updateRouteDate(RouteData data);

  RouteCollection get routeCollection;

  bool get hasEntries;

  T? innerRouterOf<T extends RoutingController>(String routeName) {
    if (childControllers.isEmpty) {
      return null;
    }
    return childControllers.values.whereType<T>().lastOrNull(
          (c) => c.routeData.name == routeName,
        );
  }

  PageBuilder get pageBuilder;

  @optionalTypeArgs
  Future<bool> pop<T extends Object?>([T? result]);

  @optionalTypeArgs
  Future<bool> popTop<T extends Object?>([T? result]) =>
      topMostRouter().pop<T>(result);

  bool get canPopSelfOrChildren;

  List<RouteMatch> get currentSegments {
    final currentData = currentChild;
    final segments = <RouteMatch>[];
    if (currentData != null) {
      segments.add(currentData.route);
      final childCtrl = childControllers[currentData.key];
      if (childCtrl?.hasEntries == true) {
        segments.addAll(childCtrl!.currentSegments);
      } else if (currentData.hasPendingChildren) {
        segments.addAll(
          currentData.pendingChildren.last.flattened,
        );
      }
    }
    return segments;
  }

  @override
  String toString() => '${routeData.name} Router';

  Future<void> _navigateAll(
    List<RouteMatch> routes, {
    OnNavigationFailure? onFailure,
  });
}

class TabsRouter extends RoutingController {
  @override
  final RoutingController? _parent;
  @override
  final LocalKey key;
  @override
  final RouteCollection routeCollection;
  @override
  final PageBuilder pageBuilder;
  @override
  final RouteMatcher matcher;
  RouteData _routeData;
  int _activeIndex = 0;
  @override
  bool managedByWidget;
  OnTabNavigateCallBack? onNavigate;
  final int homeIndex;

  TabsRouter({
    required this.routeCollection,
    required this.pageBuilder,
    required this.key,
    required RouteData routeData,
    this.managedByWidget = false,
    this.onNavigate,
    this.homeIndex = -1,
    RoutingController? parent,
    int? initialIndex,
  })  : matcher = RouteMatcher(routeCollection),
        _activeIndex = initialIndex ?? 0,
        _parent = parent,
        _routeData = routeData {
    if (parent != null) {
      var hasPendingSubNavigation = routeData.hasPendingChildren &&
          routeData.pendingChildren.last.hasChildren;
      addListener(
        () {
          if (!hasPendingSubNavigation) {
            root.notifyListeners();
          } else {
            hasPendingSubNavigation = false;
          }
        },
      );
    }
  }

  @override
  RouteData get routeData => _routeData;

  @override
  void _updateRouteDate(RouteData data) {
    _routeData = data;
    for (final page in _pages) {
      page.routeData._updateParentData(data);
    }
  }

  @override
  RouteData get current {
    return currentChild ?? routeData;
  }

  @override
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
  RoutingController get topMost => topMostRouter();

  @override
  RoutingController topMostRouter({bool ignorePagelessRoutes = false}) {
    final activeKey = _activePage?.routeData.key;
    if (childControllers.containsKey(activeKey)) {
      return childControllers[activeKey]!.topMostRouter(
        ignorePagelessRoutes: ignorePagelessRoutes,
      );
    }
    return this;
  }

  @override
  bool get hasEntries => _pages.isNotEmpty;

  @override
  @optionalTypeArgs
  Future<bool> pop<T extends Object?>([T? result]) {
    if (homeIndex != -1 && _activeIndex != homeIndex) {
      setActiveIndex(homeIndex);
      return SynchronousFuture<bool>(true);
    } else if (_parent != null) {
      return _parent!.pop<T>(result);
    } else {
      return SynchronousFuture<bool>(false);
    }
  }

  void setupRoutes(List<PageRouteInfo> routes) {
    final routesToPush = _matchAllOrReportFailure(routes)!;
    if (_routeData.hasPendingChildren) {
      final preMatchedRoute = _routeData.pendingChildren.last;
      final correspondingRouteIndex = routes.indexWhere(
        (r) => r.routeName == preMatchedRoute.name,
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
    _routeData.pendingChildren.clear();
  }

  void _pushAll(List<RouteMatch> routes) {
    for (final route in routes) {
      final data = _createRouteData(route, routeData);
      _pages.add(pageBuilder(data));
    }
  }

  void replaceAll(List<PageRouteInfo> routes) {
    final routesToPush = _matchAllOrReportFailure(routes)!;
    _pages.clear();
    _pushAll(routesToPush);
    final targetIndex = _activeIndex >= _pages.length ? 0 : _activeIndex;
    setActiveIndex(targetIndex, notify: false);
  }

  @override
  Future<void> _navigateAll(
    List<RouteMatch> routes, {
    OnNavigationFailure? onFailure,
  }) async {
    if (routes.isNotEmpty) {
      final mayUpdateRoute = routes.last;

      final pageToUpdateIndex = _pages.indexWhere(
        (p) => p.routeKey == mayUpdateRoute.key,
      );

      if (pageToUpdateIndex != -1) {
        if (!managedByWidget) {
          setActiveIndex(pageToUpdateIndex);
        } else {
          onNavigate?.call(mayUpdateRoute, false);
        }
        final mayUpdateController = childControllers[mayUpdateRoute.key];

        if (mayUpdateController != null) {
          final newRoutes = mayUpdateRoute.children ?? const [];
          if (mayUpdateController.managedByWidget) {
            mayUpdateController._onNavigate(newRoutes, false);
          }
          return mayUpdateController._navigateAll(
            newRoutes,
            onFailure: onFailure,
          );
        } else {
          final data = _createRouteData(mayUpdateRoute, routeData);
          _pages[pageToUpdateIndex] = pageBuilder(data);
        }
      }
      _updateSharedPathData(
        queryParams: mayUpdateRoute.queryParams.rawMap,
        fragment: mayUpdateRoute.fragment,
      );
    }

    return SynchronousFuture(null);
  }

  StackRouter? stackRouterOfIndex(int index) {
    if (childControllers.isEmpty) {
      return null;
    }
    final routeKey = _pages[index].routeData.key;
    if (childControllers[routeKey] is StackRouter) {
      return childControllers[routeKey]! as StackRouter;
    } else {
      return null;
    }
  }

  @override
  bool get canPopSelfOrChildren {
    if (childControllers.containsKey(_pages[_activeIndex].routeData.key)) {
      return childControllers[_pages[_activeIndex].routeData.key]!
          .canPopSelfOrChildren;
    }
    return false;
  }

  @override
  void _updateSharedPathData({
    Map<String, dynamic> queryParams = const {},
    String fragment = '',
    bool includeAncestors = false,
  }) {
    final newData = _pages[activeIndex].routeData;
    final route = newData.route;
    newData._updateRoute(
      route.copyWith(
        queryParams: Parameters(queryParams),
        fragment: fragment,
      ),
    );
    if (includeAncestors && _parent != null) {
      _parent!
          ._updateSharedPathData(queryParams: queryParams, fragment: fragment);
    }
  }

  @override
  void _onNavigate(List<RouteMatch> routes, bool initial) {
    if (routes.isNotEmpty) {
      onNavigate?.call(routes.last, initial);
    }
  }

  @override
  NavigationHistory get navigationHistory => root.navigationHistory;
}

abstract class StackRouter extends RoutingController {
  @override
  final RoutingController? _parent;
  @override
  final LocalKey key;
  final GlobalKey<NavigatorState> _navigatorKey;
  final OnNestedNavigateCallBack? onNavigate;

  StackRouter({
    required this.key,
    this.onNavigate,
    RoutingController? parent,
    GlobalKey<NavigatorState>? navigatorKey,
  })  : _navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>(),
        _parent = parent {
    if (parent != null) {
      var hasPendingSubNavigation = routeData.hasPendingChildren &&
          routeData.pendingChildren.last.hasChildren;
      addListener(
        () {
          if (!hasPendingSubNavigation) {
            root.notifyListeners();
          } else {
            hasPendingSubNavigation = false;
          }
        },
      );
    }
    pagelessRoutesObserver.addListener(notifyListeners);
  }

  final Map<AutoRedirectGuard, VoidCallback> _redirectGuardsListeners = {};

  void _attachRedirectGuard(AutoRedirectGuard guard) {
    final stackRouters = _buildRoutersHierarchy().whereType<StackRouter>();

    if (stackRouters
        .any((r) => r._redirectGuardsListeners.containsKey(guard))) {
      return;
    }
    guard.addListener(
      _redirectGuardsListeners[guard] = () {
        guard._reevaluate(this);
      },
    );
  }

  void _removeRedirectGuard(AutoRedirectGuard guard) {
    guard.removeListener(_redirectGuardsListeners[guard]!);
    _redirectGuardsListeners.remove(guard);
  }

  @override
  void dispose() {
    super.dispose();
    _redirectGuardsListeners.forEach(
      (guard, listener) {
        guard.removeListener(listener);
        guard.dispose();
      },
    );
    pagelessRoutesObserver.removeListener(notifyListeners);
    pagelessRoutesObserver.dispose();
  }

  @override
  int get stateHash => super.stateHash ^ hasPagelessTopRoute.hashCode;

  late final pagelessRoutesObserver = PagelessRoutesObserver();

  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  @override
  RouteCollection get routeCollection;

  @override
  PageBuilder get pageBuilder;

  @override
  RouteMatcher get matcher;

  @override
  bool get canPopSelfOrChildren {
    if (_pages.length > 1 || hasPagelessTopRoute) {
      return true;
    } else if (_pages.isNotEmpty &&
        childControllers.containsKey(_pages.last.routeData.key)) {
      return childControllers[_pages.last.routeData.key]!.canPopSelfOrChildren;
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

  // widgets pushed using this method
  // don't have paths nor effect url
  Future<T?> pushWidget<T extends Object?>(
    Widget widget, {
    RouteTransitionsBuilder? transitionBuilder,
    bool fullscreenDialog = false,
    Duration transitionDuration = const Duration(milliseconds: 300),
  }) {
    final navigator = _navigatorKey.currentState;
    assert(navigator != null);
    return navigator!.push<T>(
      AutoPageRouteBuilder<T>(
        child: widget,
        fullscreenDialog: fullscreenDialog,
        transitionBuilder: transitionBuilder,
        transitionDuration: transitionDuration,
      ),
    );
  }

  // routes pushed using this method
  // don't have paths nor effect url
  Future<T?> pushNativeRoute<T extends Object?>(Route<T> route) {
    final navigator = _navigatorKey.currentState;
    assert(navigator != null);
    return navigator!.push<T>(route);
  }

  @override
  RoutingController topMostRouter({bool ignorePagelessRoutes = false}) {
    if (childControllers.isNotEmpty &&
        (ignorePagelessRoutes || !hasPagelessTopRoute)) {
      final topRouteKey = currentChild?.key;
      if (childControllers.containsKey(topRouteKey)) {
        return childControllers[topRouteKey]!.topMostRouter(
          ignorePagelessRoutes: ignorePagelessRoutes,
        );
      }
    }
    return this;
  }

  @override
  RoutingController get topMost => topMostRouter();

  @override
  RouteData get topRoute => topMostRouter(ignorePagelessRoutes: true).current;

  bool get hasPagelessTopRoute => pagelessRoutesObserver.hasPagelessTopRoute;

  @override
  void _updateSharedPathData({
    Map<String, dynamic> queryParams = const {},
    String fragment = '',
    bool includeAncestors = false,
  }) {
    for (var index = 0; index < _pages.length; index++) {
      final data = _pages[index].routeData;
      final route = data.route;
      data._updateRoute(
        route.copyWith(
          queryParams: Parameters(queryParams),
          fragment: fragment,
        ),
      );
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
    _removeRoute(route._match, notify: notify);
  }

  void _removeRoute(RouteMatch route, {bool notify = true}) {
    final pageIndex = _pages.lastIndexWhere((p) => p.routeKey == route.key);
    if (pageIndex != -1) {
      _pages.removeAt(pageIndex);
    }

    final stack = _pages.map((e) => e.routeData._match);
    for (final guard in route.guards.whereType<AutoRedirectGuard>()) {
      if (!stack.any((r) => r.guards.contains(guard))) {
        _removeRedirectGuard(guard);
      }
    }

    _updateSharedPathData(includeAncestors: true);
    if (childControllers.containsKey(route.key)) {
      childControllers.remove(route.key);
    }
    if (notify) {
      notifyListeners();
    }
  }

  @override
  void _onNavigate(List<RouteMatch> routes, bool initial) {
    onNavigate?.call(routes, initial);
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
  Future<T?> push<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) async {
    return _findStackScope(route)._push<T>(route, onFailure: onFailure);
  }

  StackRouter _findStackScope(PageRouteInfo route) {
    final stackRouters = topMostRouter(ignorePagelessRoutes: true)
        ._buildRoutersHierarchy()
        .whereType<StackRouter>();
    return stackRouters.firstWhere(
      (c) => c._canHandleNavigation(route),
      orElse: () => this,
    );
  }

  Future<dynamic> _popUntilOrPushAll(
    List<RouteMatch> routes, {
    OnNavigationFailure? onFailure,
  }) async {
    final anchor = routes.first;
    final anchorPage = _pages.lastOrNull(
      (p) => p.routeKey == anchor.key,
    );
    if (anchorPage != null) {
      for (final candidate
          in List<AutoRoutePage>.unmodifiable(_pages).reversed) {
        _pages.removeLast();
        if (candidate.routeKey == anchorPage.routeKey) {
          break;
        } else {
          if (childControllers.containsKey(candidate.routeKey)) {
            childControllers.remove(candidate.routeKey);
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
    final match = _matchOrReportFailure(route, onFailure);
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
    );
  }

  Future<void> popAndPushAll(
    List<PageRouteInfo> routes, {
    OnNavigationFailure? onFailure,
  }) {
    assert(routes.isNotEmpty);
    final scope = _findStackScope(routes.first);
    scope.pop();
    return scope._pushAll(routes, onFailure: onFailure);
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
    for (final candidate in List<AutoRoutePage>.unmodifiable(_pages).reversed) {
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
    for (final entry in List<AutoRoutePage>.unmodifiable(_pages)) {
      if (predicate(entry.routeData)) {
        didRemove = true;
        _pages.remove(entry);
      }
    }
    notifyListeners();
    return didRemove;
  }

  Future<void> updateDeclarativeRoutes(List<PageRouteInfo> routes) async {
    _pages.clear();
    for (final route in routes) {
      final match = _matchOrReportFailure(route);
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
      final route = routes[i];
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
          final completer = _addEntry<T>(route, notify: true);
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
    for (final guard in route.guards) {
      final completer = Completer<bool>();
      guard.onNavigation(
        NavigationResolver(
          completer,
          route,
          pendingRoutes: pendingRoutes,
        ),
        this,
      );
      if (!await completer.future) {
        if (onFailure != null) {
          onFailure(RejectedByGuardFailure(route, guard));
        }
        if (guard is AutoRedirectGuard) {
          _removeRedirectGuard(guard);
        }
        return false;
      } else if (guard is AutoRedirectGuard) {
        _attachRedirectGuard(guard);
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
      final mayUpdateController = childControllers[mayUpdateRoute.key];

      if (mayUpdateController != null) {
        final newChildren = mayUpdateRoute.children ?? const [];
        if (mayUpdateController.managedByWidget) {
          mayUpdateController._onNavigate(newChildren, false);
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
    childControllers.clear();
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

  void refresh() => notifyListeners();
}

class NestedStackRouter extends StackRouter {
  @override
  final RouteMatcher matcher;
  @override
  final RouteCollection routeCollection;
  @override
  final PageBuilder pageBuilder;
  @override
  final bool managedByWidget;

  RouteData _routeData;

  NestedStackRouter({
    required this.routeCollection,
    required this.pageBuilder,
    required LocalKey key,
    required RouteData routeData,
    this.managedByWidget = false,
    required RoutingController parent,
    OnNestedNavigateCallBack? onRoutes,
    GlobalKey<NavigatorState>? navigatorKey,
  })  : matcher = RouteMatcher(routeCollection),
        _routeData = routeData,
        super(
          key: key,
          parent: parent,
          onNavigate: onRoutes,
          navigatorKey: navigatorKey,
        ) {
    _pushInitialRoutes();
  }

  @override
  RouteData get routeData => _routeData;

  @override
  void _updateRouteDate(RouteData data) {
    _routeData = data;
    for (final page in _pages) {
      page.routeData._updateParentData(data);
    }
  }

  void _pushInitialRoutes() async {
    if (_routeData.hasPendingChildren) {
      final initialRoutes = _routeData.pendingChildren;
      if (managedByWidget) {
        onNavigate?.call(initialRoutes, true);
      } else {
        await _pushAllGuarded(initialRoutes);
      }
    }
    _routeData.pendingChildren.clear();
  }

  @override
  NavigationHistory get navigationHistory => root.navigationHistory;
}

class _RouterScopeResult<T extends RoutingController> {
  final T router;
  final List<RouteMatch> matches;

  const _RouterScopeResult(this.router, this.matches);
}
