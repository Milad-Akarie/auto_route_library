import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/matcher/route_matcher.dart';
import 'package:auto_route/src/route/auto_route_config.dart';
import 'package:auto_route/src/route/errors.dart';
import 'package:auto_route/src/router/controller/navigation_history/navigation_history_base.dart';
import 'package:auto_route/src/router/transitions/custom_page_route.dart';
import 'package:auto_route/src/utils.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
part '../../route/route_data.dart';

part 'auto_route_guard.dart';

part 'auto_router_delegate.dart';

part 'root_stack_router.dart';

// ignore_for_file: deprecated_member_use_from_same_package
/// Signature of a predicate to select [RouteData]
typedef RouteDataPredicate = bool Function(RouteData route);

/// Signature of a callback used by declarative
typedef OnNestedNavigateCallBack = void Function(List<RouteMatch> routes);

/// Signature of a callback used in declarative routing
typedef RoutesBuilder = List<PageRouteInfo> Function(PendingRoutesHandler handler);

/// Signature of a callback to report route pop events
typedef RoutePopCallBack = void Function(RouteMatch route, Page<Object?> page);

/// Signature of a callback used in declarative routing
/// to report url state changes
typedef OnNavigateCallBack = void Function(UrlState tree);

/// Signature for a builder that returns a list of [NavigatorObserver]
typedef NavigatorObserversBuilder = List<NavigatorObserver> Function();

/// An Abstraction for an object that manages
/// page navigation
abstract class RoutingController with ChangeNotifier {
  final _childControllers = <RoutingController>[];
  bool _ignorePopCompleter = false;

  /// Whether [AutoRoutePage] should await for pop-completer
  bool get ignorePopCompleters => root._ignorePopCompleter;

  @visibleForTesting
  set ignorePopCompleters(bool value) {
    root._ignorePopCompleter = value;
  }

  /// This key is passed to the router scope
  /// it's used to provide build context inside auto_route guards instead of
  /// using [navigatorKey.currentContext] because it maybe null at times
  final globalRouterKey = GlobalObjectKey(UniqueKey());

  /// Holds track of the list of attached child controllers
  List<RoutingController> get childControllers => _childControllers;
  final List<AutoRoutePage> _pages = [];

  /// The instance of [NavigationHistory] to be used by this router
  ///
  /// There's only one [NavigationHistory] instance in the whole
  /// hierarchy that's built inside of the [root] navigator
  ///
  /// sub-controllers will use that instance instead of creating their own
  NavigationHistory get navigationHistory => root.navigationHistory;

  /// See [NavigationHistory.markUrlStateForReplace]
  void markUrlStateForReplace() => navigationHistory.markUrlStateForReplace();

  bool _markedForDataUpdate = false;

  /// Adds the given controller to the list of [childControllers]
  void attachChildController(RoutingController childController) {
    assert(!_childControllers.contains(childController));
    _childControllers.add(childController);
  }

  /// removes the given controller from the list of [childControllers]
  void removeChildController(RoutingController childController) {
    _childControllers.remove(childController);
  }

  RoutingController? _topInnerControllerOf(Key? key) {
    return _childControllers.lastWhereOrNull(
      (c) => c.key == key,
    );
  }

  RoutingController? _innerControllerOfMatch(Key key) {
    return _childControllers.lastWhereOrNull(
      (c) => c.matchId == key,
    );
  }

  /// Helper to access [NavigationHistory.urlState]
  UrlState get urlState => navigationHistory.urlState;

  /// Helper to access [NavigationHistory.urlState.path]
  String get currentPath => urlState.path;

  /// Helper to access [NavigationHistory.urlState.url]
  String get currentUrl => urlState.url;

  /// Notify this controller for changes then notify root controller
  /// if they're not the same
  ///
  /// if needed rebuild the url
  void notifyAll({bool forceUrlRebuild = false}) {
    notifyListeners();
    if (forceUrlRebuild || !isRouteDataActive(current)) {
      navigationHistory.rebuildUrl();
    } else if (!isRoot) {
      root.notifyListeners();
    }
  }

  /// Builds a simplified hierarchy of current stacks
  ///
  /// This is meant to be used in testing to verify
  /// current hierarchy
  ///
  /// e.g
  ///     expect(router.currentHierarchy(),[
  ///       HierarchySegment(name: HomeRoute.name, children:[
  ///          HierarchySegment(Tab1Route.name),
  ///         ]),
  ///      ]
  ///  );
  List<HierarchySegment> currentHierarchy({
    bool asPath = false,
    bool ignorePending = false,
    bool ignoreParams = false,
  }) =>
      _getCurrentHierarchy(
        stackData,
        asPath: asPath,
        ignoreParams: ignoreParams,
        ignorePending: ignorePending,
      );

  List<HierarchySegment> _getCurrentHierarchy(
    List<RouteData> stack, {
    required bool asPath,
    required bool ignorePending,
    required bool ignoreParams,
  }) {
    final hierarchy = <HierarchySegment>[];
    for (final data in stack) {
      final segmentName = asPath ? data.match : data.name;
      final childCtrl = _topInnerControllerOf(data.key);
      final childSegments = <HierarchySegment>[];
      if (childCtrl?.hasEntries == true) {
        childSegments.addAll(_getCurrentHierarchy(
          childCtrl!.stackData,
          asPath: asPath,
          ignorePending: ignorePending,
          ignoreParams: ignoreParams,
        ));
      } else if (!ignorePending && data.hasPendingChildren) {
        childSegments.addAll(
          _getCurrentHierarchy(
            [
              for (final pendingRoute in data.pendingChildren)
                RouteData(
                  stackKey: _stackKey,
                  route: pendingRoute,
                  router: data.router,
                  pendingChildren: [...?pendingRoute.children],
                  type: data.type,
                ),
            ],
            asPath: asPath,
            ignorePending: ignorePending,
            ignoreParams: ignoreParams,
          ),
        );
      }
      hierarchy.add(
        HierarchySegment(
          segmentName,
          children: childSegments,
          pathParams: ignoreParams || data.pathParams.isEmpty ? null : data.pathParams,
          queryParams: ignoreParams || data.queryParams.isEmpty ? null : data.queryParams,
        ),
      );
    }
    return hierarchy;
  }

  /// Returns an unmodifiable lis of current pages stack data
  List<RouteData> get stackData => List.unmodifiable(_pages.map((e) => e.routeData));

  /// See [NavigationHistory.isRouteActive]
  bool isRouteActive(String routeName) {
    return navigationHistory.isRouteActive(routeName);
  }

  /// See [NavigationHistory.isRouteDataActive]
  bool isRouteDataActive(RouteData data) {
    return navigationHistory.isRouteDataActive(data);
  }

  /// See [NavigationHistory.isPathActive]
  bool isPathActive(String path) {
    return navigationHistory.isPathActive(path);
  }

  Future<List<ReevaluatableRouteMatch>> _composeMatchesForReevaluate();

  late Key _stackKey = UniqueKey();

  RouteData<T?> _createRouteData<T>(RouteMatch route, RouteData parent, {Completer<T?>? popCompleter}) {
    final routeData = RouteData<T>(
      popCompleter: popCompleter,
      route: route,
      router: this,
      parent: parent,
      stackKey: _stackKey,
      pendingChildren: route.children ?? [],
      type: route.type ?? root.defaultRouteType,
    );
    for (final ctr in _childControllers) {
      if (ctr._markedForDataUpdate && ctr.key == routeData.key) {
        ctr.updateRouteData(routeData);
        ctr._markedForDataUpdate = false;
      }
    }

    return routeData;
  }

  /// Helper to find route match
  /// See [RouteMatcher.matchByRoute]
  RouteMatch? match(PageRouteInfo route) {
    return matcher.matchByRoute(route);
  }

  RouteMatch? _matchOrReportFailure(
    PageRouteInfo route, [
    OnNavigationFailure? onFailure,
  ]) {
    var match = matcher.matchByRoute(route);
    if (match != null) {
      return match;
    } else {
      match = matcher.buildPathTo(route);
      if (match == null) {
        if (onFailure != null) {
          onFailure(RouteNotFoundFailure(route.routeName));
          return null;
        } else {
          throw FlutterError("Failed to navigate to ${route.routeName}");
        }
      } else {
        return match;
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

  /// Whether is router is used by a declarative-routing widget
  bool get managedByWidget;

  bool _canHandleNavigation(PageRouteInfo route) {
    return routeCollection.containsKey(route.routeName);
  }

  _RouterScopeResult<T>? _findPathScopeOrReportFailure<T extends RoutingController>(String path,
      {bool includePrefixMatches = false, OnNavigationFailure? onFailure}) {
    final routers = _topMostRouter(ignorePagelessRoutes: true)._buildRoutersHierarchy().whereType<T>();

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
        RouteNotFoundFailure(path),
      );
    } else {
      throw FlutterError('Can not navigate to $path');
    }
    return null;
  }

  RoutingController _findScope<T extends RoutingController>(PageRouteInfo route) {
    return _topMostRouter(ignorePagelessRoutes: true)._buildRoutersHierarchy().firstWhere(
          (r) => r._canHandleNavigation(route),
          orElse: () => this,
        );
  }

  /// Pops until given [route], if it already exists in stack
  /// otherwise adds it to the stack (good for web Apps and to avoid duplicate entries).
  ///
  /// if [onFailure] callback is provided, navigation errors will be passed to it
  /// otherwise they'll be thrown
  Future<dynamic> navigate(PageRouteInfo route, {OnNavigationFailure? onFailure}) async {
    return _findScope(route)._navigate(route, onFailure: onFailure);
  }

  /// Pops until given [path], if it already exists in stack
  /// otherwise adds it to the stack
  ///
  /// if [includePrefixMatches] is true prefixed-matches
  /// will be added to to target destination
  /// see [RouteMatcher.matchUri]
  ///
  /// if [onFailure] callback is provided, navigation errors will be passed to it
  /// otherwise they'll be thrown
  Future<void> navigatePath(
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
      return scope.router._navigateAll(scope.matches);
    }
    return SynchronousFuture(null);
  }

  /// Pops until given [path], if it already exists in stack
  @Deprecated('Use navigatePath instead')
  Future<void> navigateNamed(
    String path, {
    bool includePrefixMatches = false,
    OnNavigationFailure? onFailure,
  }) =>
      navigatePath(
        path,
        includePrefixMatches: includePrefixMatches,
        onFailure: onFailure,
      );

  void _onNavigate(List<RouteMatch> routes);

  Future<dynamic> _navigate(PageRouteInfo route, {OnNavigationFailure? onFailure}) async {
    final match = _matchOrReportFailure(route, onFailure);
    if (match != null) {
      return _navigateAll([match], onFailure: onFailure);
    } else {
      return SynchronousFuture(null);
    }
  }

  List<RoutingController> _buildRoutersHierarchy() {
    void collectRouters(RoutingController currentParent, List<RoutingController> all) {
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

  /// Takes a state snapshot of the current segments
  int get stateHash => const ListEquality().hash(_addedSegments) ^ pageCount;

  /// The Identifier key of this routing controller
  Key get key;

  /// The unique identifier of the [RouteMatch] linked to this controller
  Key get matchId;

  /// The matcher used by this controller
  /// see [RouteMatcher]
  RouteMatcher get matcher;

  /// The current pages stack of this controller
  List<AutoRoutePage> get stack;

  RoutingController? get _parent;

  /// Whether this controller has the top-most visible page
  bool get isTopMost => this == _topMostRouter();

  /// Casts parent controller to [T]
  ///
  /// returns null if [_parent]
  T? parent<T extends RoutingController>() {
    return _parent == null ? null : _parent as T;
  }

  /// See [NavigationHistory.canNavigateBack]
  bool get canNavigateBack => navigationHistory.canNavigateBack;

  /// See [NavigationHistory.back]
  void back() => navigationHistory.back();

  /// See [NavigationHistory.pushPathState]
  void pushPathState(Object? state) => navigationHistory.pushPathState(state);

  /// See [NavigationHistory.pathState]
  Object? get pathState => navigationHistory.pathState;

  /// Returns the root router as [RootStackRouter]
  RootStackRouter get root => (_parent?.root ?? this) as RootStackRouter;

  /// Returns parent route as [StackRouter]
  StackRouter? get parentAsStackRouter => parent<StackRouter>();

  /// Whether is controller is the root of all controllers
  bool get isRoot => _parent == null;

  RoutingController _topMostRouter({bool ignorePagelessRoutes = false});

  /// Finds the router with top-most visible page
  ///
  /// if [ignorePagelessRoutes] is true pageless routes
  /// will be ignored
  ///
  /// What is a (PagelessRoute)?
  /// [Route] that does not correspond to a [Page] object is called a pageless
  /// route and is tied to the [Route] that _does_ correspond to a [Page] object
  /// that is below it in the history.
  RoutingController topMostRouter({bool ignorePagelessRoutes = false}) {
    return root._topMostRouter(ignorePagelessRoutes: ignorePagelessRoutes);
  }

  /// The active child representation of an implementation of this controller
  ///
  /// e.g it could be the top-most route of a [StackRouter] or
  /// the child corresponding with activeIndex in [TabsRouter]
  RouteData? get currentChild;

  /// Returns [currentChild] if it's rendered
  /// otherwise returns parent [routeData]
  RouteData get current;

  /// The top-most rendered route
  RouteData get topRoute => _topMostRouter().current;

  /// The top-most rendered or pending route match
  RouteMatch get topMatch => topRoute.topMatch;

  /// The data of the parent route
  RouteData get routeData;

  /// Updates the value of [routeData]
  void updateRouteData(RouteData data);

  /// The list of routes consumed by this controller
  RouteCollection get routeCollection;

  /// The top-most visible page
  AutoRoutePage? get topPage => _topMostRouter()._pages.lastOrNull;

  /// Whether this controller has rendered pages
  bool get hasEntries => _pages.isNotEmpty;

  /// The count of rendered pages
  int get pageCount => _pages.length;

  /// Finds a child route corresponding to [routeName]
  /// and casts it to [T]
  ///
  /// returns null if it does not find it
  T? innerRouterOf<T extends RoutingController>(String routeName) {
    if (_childControllers.isEmpty) {
      return null;
    }
    return _childControllers.whereType<T>().lastWhereOrNull(
          ((c) => c.routeData.name == routeName),
        );
  }

  /// Clients can either pop their own [_pages] stack
  /// or defer the call to a parent controller
  ///
  /// see [Navigator.maybePop(context)] for more details
  @optionalTypeArgs
  Future<bool> maybePop<T extends Object?>([T? result]);

  /// Calls [maybePop] on the controller with the top-most visible page
  @optionalTypeArgs
  Future<bool> maybePopTop<T extends Object?>([T? result]) => _topMostRouter().maybePop<T>(result);

  /// Clients can either pop their own [_pages] stack
  /// or defer the call to a parent controller
  ///
  /// see [Navigator.pop(context)] for more details
  @optionalTypeArgs
  void pop<T extends Object?>([T? result]);

  /// Calls [pop] on the controller with the top-most visible page
  @optionalTypeArgs
  void popTop<T extends Object?>([T? result]) => _topMostRouter().pop<T>(result);

  /// Whether this controller can preform [maybePop]
  ///
  /// if [ignoreChildRoutes] is true
  /// it will only check whether this controller has multiple entire
  /// and not care about pop-able child controllers
  ///
  /// if [ignoreParentRoutes] is true
  /// it will only check whether this controller has multiple entire
  /// and not care about pop-able parent controllers
  ///
  /// if [ignorePagelessRoutes] is true
  /// page-lss routes will not be considered in the calculation
  bool canPop({
    bool ignoreChildRoutes = false,
    bool ignoreParentRoutes = false,
    bool ignorePagelessRoutes = false,
  });

  /// returns true if any child controller can pop
  bool childrenCanPop({
    bool ignorePagelessRoutes = false,
  }) {
    return _childControllers.any(
      (c) => c.canPop(
        ignorePagelessRoutes: ignorePagelessRoutes,
        ignoreParentRoutes: true,
      ),
    );
  }

  /// returns true if the active child controller can pop
  bool activeRouterCanPop({bool ignorePagelessRoutes = false}) {
    final innerRouter = _topInnerControllerOf(currentChild?.key);
    if (innerRouter != null) {
      return innerRouter.canPop(
        ignorePagelessRoutes: ignorePagelessRoutes,
        ignoreParentRoutes: true,
      );
    }
    return false;
  }

  /// Collects the top-most visitable current-child of
  /// every top-most nested controller considering this controller as root
  List<RouteMatch> get currentSegments {
    var currentData = currentChild;
    final segments = <RouteMatch>[];
    if (currentData != null) {
      segments.add(currentData.route);
      final childCtrl = _topInnerControllerOf(currentData.key);
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

  /// this is an indicator for controller state changes,
  /// every controller's state is considered updated if it's stateHash or any of it's children's stateHash changes
  List<RouteMatch> get _addedSegments {
    var currentData = currentChild;
    final segments = <RouteMatch>[];
    if (currentData != null) {
      segments.add(currentData.route);
      final childCtrl = _topInnerControllerOf(currentData.key);
      if (childCtrl?.hasEntries == true) {
        segments.addAll(childCtrl!._addedSegments);
      }
    }
    return segments;
  }

  /// Finds match of [path] then returns a route-able entity
  PageRouteInfo? buildPageRoute(String? path, {bool includePrefixMatches = true}) {
    if (path == null) return null;
    return matcher.match(path, includePrefixMatches: includePrefixMatches)?.firstOrNull?.toPageRouteInfo();
  }

  /// Finds matches of [path] then returns a list of route-able entities
  List<PageRouteInfo>? buildPageRoutesStack(String? path, {bool includePrefixMatches = true}) {
    if (path == null) return null;
    return matcher.match(path, includePrefixMatches: includePrefixMatches)?.map((m) => m.toPageRouteInfo()).toList();
  }

  @override
  String toString() => '${routeData.name} Router';

  Future<void> _navigateAll(
    List<RouteMatch> routes, {
    OnNavigationFailure? onFailure,
    bool isReevaluating = false,
  });

  Future<void> _navigateAllRoutes(List<PageRouteInfo> routes, {OnNavigationFailure? onFailure}) {
    final matches = _matchAllOrReportFailure(routes, onFailure);
    if (matches != null) {
      return _navigateAll(matches, onFailure: onFailure);
    }
    return SynchronousFuture(null);
  }
}

/// An implementation of a [RoutingController] that handles parallel routeing
///
/// aka Tab-Routing
class TabsRouter extends RoutingController {
  @override
  final RoutingController? _parent;
  @override
  final Key key;
  @override
  final Key matchId;
  @override
  final RouteCollection routeCollection;
  @override
  final RouteMatcher matcher;
  RouteData _routeData;
  int _activeIndex = 0;
  int? _previousIndex;

  /// The index to pop from
  ///
  /// if activeIndex != homeIndex
  /// set activeIndex to homeIndex
  /// else pop parent
  final int homeIndex;

  /// Default constructor
  TabsRouter(
      {required this.routeCollection,
      required this.key,
      required RouteData routeData,
      this.homeIndex = -1,
      required this.preload,
      required this.matchId,
      RoutingController? parent})
      : matcher = RouteMatcher(routeCollection),
        _parent = parent,
        _routeData = routeData;

  /// Called to preload a page before other navigation events occur
  /// if it returns true, the page has been preloaded, otherwise we assume it's already loaded
  bool Function(int index) preload;

  @override
  RouteData get routeData => _routeData;

  @override
  void updateRouteData(RouteData data) {
    _routeData = data;
    for (var page in _pages) {
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

  /// The index of active page
  int get activeIndex => _activeIndex;

  /// The index of previous active page
  int? get previousIndex => _previousIndex;

  /// Updates [_activeIndex] and triggers a rebuild
  void setActiveIndex(int index, {bool notify = true}) {
    assert(index >= 0 && index < _pages.length);
    if (_activeIndex != index) {
      final didPreload = preload(index);
      _previousIndex = _activeIndex;
      _activeIndex = index;
      if (notify) {
        if (didPreload && SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            notifyAll();
          });
        } else {
          notifyAll();
        }
      }
    }
  }

  @override
  List<AutoRoutePage> get stack => List.unmodifiable(_pages);

  AutoRoutePage? get _activePage {
    return _pages.isEmpty ? null : _pages[_activeIndex];
  }

  @override
  RoutingController _topMostRouter({bool ignorePagelessRoutes = false}) {
    var key = _activePage?.routeData.key;
    final innerRouter = _topInnerControllerOf(key);
    if (innerRouter != null) {
      return innerRouter._topMostRouter(
        ignorePagelessRoutes: ignorePagelessRoutes,
      );
    }
    return this;
  }

  @override
  @optionalTypeArgs
  Future<bool> maybePop<T extends Object?>([T? result]) {
    if (homeIndex != -1 && _activeIndex != homeIndex) {
      setActiveIndex(homeIndex);
      return SynchronousFuture<bool>(true);
    } else if (_parent != null) {
      return _parent!.maybePop<T>(result);
    } else {
      return SynchronousFuture<bool>(false);
    }
  }

  @override
  @optionalTypeArgs
  void pop<T extends Object?>([T? result]) {
    if (homeIndex != -1 && _activeIndex != homeIndex) {
      setActiveIndex(homeIndex);
    } else if (_parent != null) {
      _parent!.pop(result);
    }
  }

  /// Pushes given [routes] to [_pages] stack
  /// after match validation and deciding initial index
  void setupRoutes(List<PageRouteInfo>? routes) {
    final routesToPush = _resolveRoutes(routes);
    if (_routeData.hasPendingChildren) {
      final preMatchedRoute = _routeData.pendingChildren.last;
      final correspondingRouteIndex = routesToPush.indexWhere(
        (r) => r.key == preMatchedRoute.key,
      );
      if (correspondingRouteIndex != -1) {
        routesToPush[correspondingRouteIndex] = preMatchedRoute;
        _previousIndex = _activeIndex;
        _activeIndex = correspondingRouteIndex;
      }
    }

    if (routesToPush.isNotEmpty) {
      _pushAll(routesToPush, fromDefault: routes == null);
    }
    _routeData.pendingChildren.clear();
  }

  void _pushAll(List<RouteMatch> routes, {required bool fromDefault}) {
    for (var route in routes) {
      var data = _createRouteData(route, routeData);
      try {
        _pages.add(data.buildPage());
      } on MissingRequiredParameterError catch (e) {
        if (fromDefault) {
          throw FlutterError(
            'Can not automatically navigate to ${route.name} because it has required parameters. '
            'Routes must be added manually to AutoTabsRouter'
            '\n${e.message}',
          );
        } else {
          rethrow;
        }
      }
    }
  }

  @override
  Future<List<ReevaluatableRouteMatch>> _composeMatchesForReevaluate() async {
    final matches = <ReevaluatableRouteMatch>[];
    for (final page in stack) {
      final match = page.routeData._match;
      final ReevaluatableRouteMatch reMatch;
      final childCtrl = _innerControllerOfMatch(match.id);
      if (childCtrl != null) {
        reMatch = ReevaluatableRouteMatch(
          currentPage: page,
          originalMatch: match.copyWith(
            children: await childCtrl._composeMatchesForReevaluate(),
          ),
        );
      } else {
        reMatch = ReevaluatableRouteMatch(
          currentPage: page,
          originalMatch: match.copyWith(children: const []),
        );
      }
      page.routeData._onStartReevaluating(reMatch.originalMatch);
      matches.add(reMatch);
    }
    return matches;
  }

  List<RouteMatch> _resolveRoutes(List<PageRouteInfo>? routes) {
    final List<PageRouteInfo> routesToUse;
    if (routes != null) {
      routesToUse = routes;
    } else {
      routesToUse = routeCollection.routes.where((e) => e is! RedirectRoute).map((e) => PageRouteInfo(e.name)).toList();
    }
    return _matchAllOrReportFailure(routesToUse)!;
  }

  /// Resets [_pages] stack with given [routes]
  /// and sets [previousActiveRoute] as active index if provided
  void replaceAll(List<PageRouteInfo>? routes, int previousIndex) {
    final routesToPush = _resolveRoutes(routes);
    final previousActiveRoute = stackData[previousIndex];

    _pages.clear();
    _childControllers.clear();
    _pushAll(routesToPush, fromDefault: routes == null);
    var targetIndex = routesToPush.indexWhere((r) => r.name == previousActiveRoute.name);
    if (targetIndex == -1) {
      targetIndex = homeIndex == -1 ? 0 : homeIndex;
    }
    setActiveIndex(targetIndex, notify: false);
  }

  @override
  Future<void> _navigateAll(
    List<RouteMatch> routes, {
    OnNavigationFailure? onFailure,
    bool isReevaluating = false,
  }) async {
    final routesToProcess = isReevaluating ? routes : routes.reversed.take(1);
    for (final mayUpdateRoute in routesToProcess) {
      final pageToUpdateIndex = _pages.indexWhere(
        (p) => p.routeKey == mayUpdateRoute.key,
      );

      if (pageToUpdateIndex != -1) {
        RouteMatch routeToBeUpdated = _pages[pageToUpdateIndex].routeData._match;
        final bool shouldNotify = mayUpdateRoute != routeToBeUpdated;

        routeToBeUpdated = routeToBeUpdated.copyWith(
          children: mayUpdateRoute.children ?? const [],
          queryParams: mayUpdateRoute.queryParams,
          fragment: mayUpdateRoute.fragment,
          pathParams: mayUpdateRoute.params,
          segments: mayUpdateRoute.segments,
          stringMatch: mayUpdateRoute.stringMatch,
          redirectedFrom: mayUpdateRoute.redirectedFrom,
          args: mayUpdateRoute.args,
          key: mayUpdateRoute.key,
          autoFilled: mayUpdateRoute.autoFilled,
          evaluatedGuards: mayUpdateRoute.evaluatedGuards,
        );

        for (final ctr in _childControllers) {
          if (ctr.matchId == _pages[pageToUpdateIndex].routeData.matchId) {
            ctr._markedForDataUpdate = true;
          }
        }

        if (mayUpdateRoute is ReevaluatableRouteMatch) {
          _pages[pageToUpdateIndex] = mayUpdateRoute.currentPage;
          mayUpdateRoute.currentPage.routeData._onEndReevaluating(routeToBeUpdated);
        } else {
          final data = _createRouteData(routeToBeUpdated, routeData);
          _pages[pageToUpdateIndex] = data.buildPage();
        }

        final hasInitCtrl = _topInnerControllerOf(routeToBeUpdated.key) != null;

        if (!isReevaluating && _activeIndex != pageToUpdateIndex) {
          setActiveIndex(pageToUpdateIndex);
        } else if (shouldNotify) {
          notifyAll();
        }

        if (hasInitCtrl) {
          final mayUpdateController = _topInnerControllerOf(routeToBeUpdated.key);
          if (mayUpdateController != null) {
            final newRoutes = routeToBeUpdated.children ?? const [];
            mayUpdateController._navigateAll(
              newRoutes,
              onFailure: onFailure,
              isReevaluating: isReevaluating,
            );
          }
        }
      }
      if (!isReevaluating && _activeIndex != pageToUpdateIndex) {
        _updateSharedPathData(
          queryParams: mayUpdateRoute.queryParams.rawMap,
          fragment: mayUpdateRoute.fragment,
          includeAncestors: false,
        );
      }
    }

    return SynchronousFuture(null);
  }

  /// If page corresponding with [index]
  /// has an attached [StackRouter] returns it
  /// otherwise returns null
  StackRouter? stackRouterOfIndex(int index) {
    if (_childControllers.isEmpty) {
      return null;
    }
    final matchId = _pages[index].routeData.matchId;
    final innerRouter = _innerControllerOfMatch(matchId);
    if (innerRouter is StackRouter) {
      return innerRouter;
    } else {
      return null;
    }
  }

  @override
  bool canPop({
    bool ignoreChildRoutes = false,
    bool ignoreParentRoutes = false,
    bool ignorePagelessRoutes = false,
  }) {
    if (!ignoreChildRoutes) {
      final innerRouter = _topInnerControllerOf(_activePage?.routeKey);
      if (innerRouter != null &&
          innerRouter.canPop(
            ignorePagelessRoutes: ignorePagelessRoutes,
            ignoreParentRoutes: true,
          )) {
        return true;
      }
    }
    if (!ignoreParentRoutes && _parent != null) {
      return _parent!.canPop(
        ignoreChildRoutes: true,
        ignorePagelessRoutes: ignorePagelessRoutes,
      );
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
    newData._updateRoute(route.copyWith(
      queryParams: Parameters(queryParams),
      fragment: fragment,
    ));
    if (includeAncestors && _parent != null) {
      _parent!._updateSharedPathData(queryParams: queryParams, fragment: fragment);
    }
  }

  @override
  void _onNavigate(List<RouteMatch> routes) {}

  @override
  bool get managedByWidget => false;
}

/// An implementation of a [RoutingController] that handles stack navigation
abstract class StackRouter extends RoutingController {
  @override
  final RoutingController? _parent;
  @override
  final Key key;

  @override
  final Key matchId;

  final GlobalKey<NavigatorState> _navigatorKey;
  final OnNestedNavigateCallBack? _onNavigateCallback;

  /// Default constructor
  StackRouter({
    required this.key,
    required this.matchId,
    OnNestedNavigateCallBack? onNavigate,
    RoutingController? parent,
    GlobalKey<NavigatorState>? navigatorKey,
  })  : _navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>(),
        _onNavigateCallback = onNavigate,
        _parent = parent;

  /// The pending routes handler for this controller
  @internal
  late final pendingRoutesHandler = PendingRoutesHandler();

  @override
  void dispose() {
    super.dispose();
    pagelessRoutesObserver.dispose();
  }

  /// Whether a reevaluation is in progress
  bool _isReevaluating = false;

  /// Re-builds all routes in stack and reevaluate guarded
  /// once by re-visiting the onNavigation method when evaluation logic changes
  ///
  /// e.g when the user is no longer authenticated
  /// and there are auth-protected routes in the stack
  Future<void> reevaluateGuards() async {
    final matches = await _composeMatchesForReevaluate();
    if (matches.isNotEmpty && !_isReevaluating) {
      _isReevaluating = true;
      await _navigateAll(matches, isReevaluating: true);
      _isReevaluating = false;
    }
    notifyAll();
  }

  @override
  Future<List<ReevaluatableRouteMatch>> _composeMatchesForReevaluate() async {
    /// wait for the current child to finish its animation
    if (currentChild?.animationCompletion case final completion?) {
      await completion;
    }
    final alreadyEvaluated = <Key, List<AutoRouteGuard>>{};
    for (var i = 0; i < activeGuardObserver.value.length; i++) {
      final entry = activeGuardObserver.value[i];
      final resolver = entry._resolver;
      if (resolver.isResolved) continue;
      resolver._isReevaluating = true;
      entry.guard.onNavigation(resolver, this);
      final result = await resolver._completer.future;
      if (result.continueNavigation) {
        alreadyEvaluated.putIfAbsent(result.route.id, () => []).add(entry.guard);
      }
    }

    final matches = <ReevaluatableRouteMatch>[];
    for (var page in stack) {
      var match = page.routeData._match;
      if (alreadyEvaluated.containsKey(match.id)) {
        match = match.copyWith(evaluatedGuards: alreadyEvaluated[match.id]);
      }
      final childCtrl = _innerControllerOfMatch(match.id);
      if (childCtrl != null) {
        final childMatches = await childCtrl._composeMatchesForReevaluate();
        match = match.copyWith(children: childMatches);
      }
      page.routeData._onStartReevaluating(match);

      /// the route maybe removed from stack at this point
      if (stackData.any((e) => e._match.id == match.id)) {
        matches.add(ReevaluatableRouteMatch(currentPage: page, originalMatch: match));
      }
    }
    return matches;
  }

  @override
  int get stateHash => super.stateHash ^ hasPagelessTopRoute.hashCode;

  /// The page-less route observer of this controller
  final pagelessRoutesObserver = PagelessRoutesObserver();

  /// The active guards observer of this controller
  final activeGuardObserver = ActiveGuardObserver();

  /// Navigator key passed to [Navigator.key]
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  @override
  RouteCollection get routeCollection;

  @override
  RouteMatcher get matcher;

  @override
  bool canPop({
    bool ignoreChildRoutes = false,
    bool ignoreParentRoutes = false,
    bool ignorePagelessRoutes = false,
  }) {
    if (_pages.length > 1 || (!ignorePagelessRoutes && hasPagelessTopRoute)) {
      return true;
    }

    if (!ignoreChildRoutes && _pages.isNotEmpty) {
      final innerRouter = _topInnerControllerOf(_pages.last.routeData.key);
      if (innerRouter != null &&
          innerRouter.canPop(
            ignoreParentRoutes: true,
            ignorePagelessRoutes: ignorePagelessRoutes,
          )) {
        return true;
      }
    }

    if (!ignoreParentRoutes && _parent != null) {
      return _parent!.canPop(
        ignorePagelessRoutes: ignorePagelessRoutes,
        ignoreChildRoutes: true,
      );
    }
    return false;
  }

  @override
  RouteData get current => currentChild ?? routeData;

  @override
  RouteData? get currentChild {
    if (_pages.isNotEmpty) {
      return _pages.last.routeData;
    }
    return null;
  }

  /// Pushes a raw widget to [Navigator]
  ///
  /// Widgets pushed using this method
  /// don't have paths nor effect url
  Future<T?> pushWidget<T extends Object?>(
    Widget widget, {
    RouteTransitionsBuilder? transitionBuilder,
    bool fullscreenDialog = false,
    Duration transitionDuration = const Duration(milliseconds: 300),
    bool opaque = true,
  }) {
    final navigator = _navigatorKey.currentState;
    assert(navigator != null);
    return navigator!.push<T>(
      AutoPageRouteBuilder<T>(
        child: widget,
        fullscreenDialog: fullscreenDialog,
        transitionBuilder: transitionBuilder,
        transitionDuration: transitionDuration,
        opaque: opaque,
      ),
    );
  }

  /// Pushes a [Route] to [Navigator]
  ///
  /// Routes pushed using this method
  /// don't have paths nor effect url
  Future<T?> pushNativeRoute<T extends Object?>(Route<T> route) {
    final navigator = _navigatorKey.currentState;
    assert(navigator != null);
    return navigator!.push<T>(route);
  }

  @override
  RoutingController _topMostRouter({bool ignorePagelessRoutes = false}) {
    if (_childControllers.isNotEmpty && (ignorePagelessRoutes || !hasPagelessTopRoute)) {
      var topRouteKey = currentChild?.key;
      final innerRouter = _topInnerControllerOf(topRouteKey);
      if (innerRouter != null) {
        return innerRouter._topMostRouter(
          ignorePagelessRoutes: ignorePagelessRoutes,
        );
      }
    }
    return this;
  }

  @override
  RouteData get topRoute => _topMostRouter(ignorePagelessRoutes: true).current;

  /// Whether the top-most route of this controller is page-less
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
  Future<bool> maybePop<T extends Object?>([T? result]) async {
    final NavigatorState? navigator = _navigatorKey.currentState;
    if (navigator == null) return SynchronousFuture<bool>(false);
    if (await navigator.maybePop<T>(result)) {
      return true;
    } else if (_parent != null) {
      return _parent!.maybePop<T>(result);
    } else {
      return false;
    }
  }

  /// Pop current route regardless if it's the last
  /// route in stack or the result of it's PopScopes
  /// see [Navigator.pop]
  @override
  @optionalTypeArgs
  void pop<T extends Object?>([T? result]) {
    final NavigatorState? navigator = _navigatorKey.currentState;
    if (navigator != null) {
      navigator.pop(result);
    }
  }

  /// Pop until given [route] if it exists in stack
  /// otherwise does nothing
  /// see [Navigator.pop]
  @Deprecated('Use pop instead')
  @optionalTypeArgs
  void popForced<T extends Object?>([T? result]) {
    return pop<T>(result);
  }

  /// Removes the very last entry from [_pages]
  bool removeLast() => _removeLast();

  /// Removes given [route] and any corresponding controllers
  ///
  /// finally calls [notifyAll] if notify is true
  void removeRoute(RouteData route, {bool notify = true}) {
    _removeRoute(route._match, notify: notify);
  }

  /// Called when Page route is popped
  /// this is not called when pageless routes are popped e.g popping a dialog
  /// that does not use [PageRoute] will not trigger this method
  void onPopPage(AutoRoutePage<Object?> page) {
    _pages.remove(page);
    _updateSharedPathData(includeAncestors: true);
    if (isRouteDataActive(page.routeData)) {
      navigationHistory.rebuildUrl();
    }
  }

  void _removeRoute(RouteMatch route, {bool notify = true}) {
    var pageIndex = _pages.lastIndexWhere((p) => p.routeKey == route.key);
    if (pageIndex != -1) {
      _pages.removeAt(pageIndex);
    }
    _updateSharedPathData(includeAncestors: true);
    if (notify) {
      notifyAll(forceUrlRebuild: true);
    }
  }

  @override
  void _onNavigate(List<RouteMatch> routes) {
    _onNavigateCallback?.call(routes);
  }

  bool _removeLast({bool notify = true}) {
    var didRemove = false;
    if (_pages.isNotEmpty) {
      removeRoute(_pages.last.routeData, notify: notify);
      didRemove = true;
    }
    return didRemove;
  }

  @override
  List<AutoRoutePage> get stack => List.unmodifiable(_pages);

  /// Adds the corresponding page to given [route] to the [_pages] stack
  ///
  /// if [onFailure] callback is provided, navigation errors will be passed to it
  /// otherwise they'll be thrown
  @optionalTypeArgs
  Future<T?> push<T extends Object?>(PageRouteInfo route, {OnNavigationFailure? onFailure}) async {
    return _findStackScope(route)._push<T>(route, onFailure: onFailure);
  }

  StackRouter _findStackScope(PageRouteInfo route) {
    final stackRouters = _topMostRouter(ignorePagelessRoutes: true)._buildRoutersHierarchy().whereType<StackRouter>();
    return stackRouters.firstWhere(
      (c) => c._canHandleNavigation(route),
      orElse: () => this,
    );
  }

  /// Inserts the corresponding page to given [route] to the [_pages] stack
  ///
  /// if [onFailure] callback is provided, navigation errors will be passed to it
  /// otherwise they'll be thrown
  Future<void> insert(PageRouteInfo route, {int index = 0, OnNavigationFailure? onFailure}) {
    return _findStackScope(route)._push(route, onFailure: onFailure, insertAt: index);
  }

  Future<dynamic> _popUntilOrPushAll(
    List<RouteMatch> matches, {
    OnNavigationFailure? onFailure,
    bool isReevaluating = false,
  }) async {
    final anchor = matches.first;
    final anchorPage = _pages.lastWhereOrNull(
      (p) => p.routeKey == anchor.key,
    );
    if (anchorPage != null) {
      for (var candidate in List<AutoRoutePage>.unmodifiable(_pages).reversed) {
        _pages.removeLast();
        if (candidate.routeKey == anchorPage.routeKey) {
          for (final ctr in _childControllers) {
            if (ctr.routeData == candidate.routeData) {
              ctr._markedForDataUpdate = true;
            }
          }
          break;
        }
      }
    }
    return _pushAllGuarded(
      matches,
      onFailure: onFailure,
      updateAncestorsPathData: false,
      returnLastRouteCompleter: false,
      isReevaluating: isReevaluating,
    );
  }

  @optionalTypeArgs
  Future<T?> _push<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
    bool notify = true,
    ValueChanged<RouteMatch>? onMatch,
    int? insertAt,
  }) async {
    assert(
      !managedByWidget,
      'Pages stack can be managed by either the Widget (AutoRouter.declarative) or the (StackRouter)',
    );
    var match = _matchOrReportFailure(route, onFailure);
    if (match == null) {
      return null;
    }
    onMatch?.call(match);
    final result = await _canNavigate(match, onFailure: onFailure);
    if (result.continueNavigation) {
      _updateSharedPathData(
        queryParams: route.rawQueryParams,
        fragment: route.fragment,
        includeAncestors: true,
      );

      return _addNewPage<T>(
        result.route,
        notify: notify,
        index: insertAt,
      );
    }
    return null;
  }

  /// Removes last entry in stack and pushes given [route]
  /// if last entry == [route] page will just be updated
  ///
  /// if [onFailure] callback is provided, navigation errors will be passed to it
  /// otherwise they'll be thrown
  @optionalTypeArgs
  Future<T?> replace<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) {
    final scope = _findStackScope(route);
    scope._removeLast(notify: false);
    markUrlStateForReplace();
    return scope._push<T>(route, onFailure: onFailure);
  }

  Future<T?> _redirect<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
    bool replace = false,
    required Function(StackRouter scope, RouteMatch match) onMatch,
  }) {
    final scope = _findStackScope(route);
    if (replace) {
      scope._removeLast(notify: false);
      markUrlStateForReplace();
    }
    return scope._push<T>(
      route,
      onFailure: onFailure,
      onMatch: (match) => onMatch(scope, match),
    );
  }

  /// Adds the corresponding pages to given [routes] list to the [_pages] stack at once
  ///
  /// if [onFailure] callback is provided, navigation errors will be passed to it
  /// otherwise they'll be thrown
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

  /// Pop the current route off the navigator and push all given [routes] in its place.
  ///
  /// if [onFailure] callback is provided, navigation errors will be passed to it
  /// otherwise they'll be thrown
  Future<void> popAndPushAll(List<PageRouteInfo> routes, {onFailure}) {
    assert(routes.isNotEmpty);
    final scope = _findStackScope(routes.first);
    scope.maybePop();
    return scope._pushAll(routes, onFailure: onFailure, notify: true);
  }

  /// Remove the whole current pages stack and push all given [routes]
  ///
  /// if [onFailure] callback is provided, navigation errors will be passed to it
  /// otherwise they'll be thrown
  ///
  /// if [updateExistingRoutes] is set to false a fresh stack
  /// will be initiated.
  Future<void> replaceAll(
    List<PageRouteInfo> routes, {
    OnNavigationFailure? onFailure,
    bool updateExistingRoutes = true,
  }) {
    return _findStackScope(routes.first)._replaceAll(
      routes,
      onFailure: onFailure,
      updateExistingRoutes: updateExistingRoutes,
    );
  }

  Future<void> _replaceAll(
    List<PageRouteInfo> routes, {
    required bool updateExistingRoutes,
    OnNavigationFailure? onFailure,
  }) async {
    final matches = _matchAllOrReportFailure(routes, onFailure);
    if (matches != null) {
      _pages.clear();
      if (!updateExistingRoutes) {
        _stackKey = UniqueKey();
      }
      markUrlStateForReplace();
      return _navigateAll(matches);
    }
    return SynchronousFuture(null);
  }

  /// Pop the whole stack except for the first entry
  void popUntilRoot() {
    assert(_navigatorKey.currentState != null);
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  /// Pop the current route off the navigator and push the given [route] in its place.
  ///
  /// if [onFailure] callback is provided, navigation errors will be passed to it
  /// otherwise they'll be thrown
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

  /// Calls [removeRoute] repeatedly until the predicate returns true.
  ///
  /// Note: [removeRoute] does not respect PopScopes
  /// if [scoped] is set to true the predicate will
  /// visit all StackRouters in hierarchy starting from
  /// top until satisfied
  bool removeUntil(RouteDataPredicate predicate, {bool scoped = true}) {
    if (scoped) {
      return _removeUntil(predicate);
    }
    final routers = _topMostRouter()._buildRoutersHierarchy();
    bool predicateWasSatisfied = false;
    for (final router in routers.whereType<StackRouter>()) {
      router._removeUntil((route) {
        return predicateWasSatisfied = predicate(route);
      });
      if (predicateWasSatisfied) break;
    }
    return predicateWasSatisfied;
  }

  /// Calls [maybePop] repeatedly on the navigator until the predicate returns true.
  ///
  /// see [Navigator.popUntil]
  ///
  /// if [scoped] is set to true the predicate will
  /// visit all StackRouters in hierarchy starting from
  /// top until satisfied
  void popUntil(RoutePredicate predicate, {bool scoped = true}) {
    if (scoped) {
      return _navigatorKey.currentState?.popUntil(predicate);
    }
    final routers = _topMostRouter()._buildRoutersHierarchy();
    bool predicateWasSatisfied = false;
    for (final router in routers.whereType<StackRouter>()) {
      final navState = router._navigatorKey.currentState;
      if (navState == null) break;
      navState.popUntil((route) {
        return predicateWasSatisfied = predicate(route);
      });
      if (predicateWasSatisfied) break;
    }
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
      notifyAll(forceUrlRebuild: true);
    }
    return didRemove;
  }

  /// Removes any route that satisfied the [predicate].
  ///
  /// Note: [removeRoute] does not respect PopScopes
  bool removeWhere(RouteDataPredicate predicate, {bool notify = true}) {
    var didRemove = false;
    for (var entry in List<AutoRoutePage>.unmodifiable(_pages)) {
      if (predicate(entry.routeData)) {
        didRemove = true;
        removeRoute(entry.routeData);
      }
    }
    if (notify) {
      notifyAll(forceUrlRebuild: true);
    }
    return didRemove;
  }

  /// Replaces the list of [_pages] with given [routes] result
  /// used by declarative routing widgets
  void updateDeclarativeRoutes(List<PageRouteInfo> routes) async {
    _pages.clear();
    final routesToPush = <RouteMatch>[];
    for (var route in routes) {
      var match = _matchOrReportFailure(route);
      if (match == null) {
        break;
      }
      if (match.guards.isNotEmpty) {
        throw FlutterError("Declarative routes can not have guards");
      }
      routesToPush.add(match);
      final data = _createRouteData(match, routeData);
      _pages.add(data.buildPage());
    }

    navigationHistory.onNewUrlState(
      UrlState.fromSegments(
        root.currentSegments,
        shouldReplace: current == routeData,
      ),
      notify: false,
    );
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
    bool isReevaluating = false,
  }) async {
    assert(
      !managedByWidget,
      'Pages stack can be managed by either the Widget (AutoRouter.declarative) or Router',
    );

    for (var i = 0; i < routes.length; i++) {
      final result = await _canNavigate(
        routes[i],
        onFailure: onFailure,
        pendingRoutes: routes.whereIndexed((index, element) => index > i).toList(),
        isReevaluating: isReevaluating,
      );

      final match = result.route;
      if (result.continueNavigation) {
        if (i != (routes.length - 1)) {
          if (match is ReevaluatableRouteMatch) {
            _addReevaluatedPage(match, notify: false);
          } else {
            _addNewPage<T>(match, notify: false);
          }
        } else {
          _updateSharedPathData(
            queryParams: match.queryParams.rawMap,
            fragment: match.fragment,
            includeAncestors: updateAncestorsPathData,
          );
          if (match is ReevaluatableRouteMatch) {
            _addReevaluatedPage(match, notify: notify);
          } else {
            final completer = _addNewPage<T>(match, notify: notify);
            if (returnLastRouteCompleter) {
              return completer;
            }
          }
        }

        if (isReevaluating && !result.reevaluateNext) {
          break;
        }
      } else {
        break;
      }
    }
    return SynchronousFuture(null);
  }

  void _addReevaluatedPage(ReevaluatableRouteMatch match, {bool notify = true}) {
    final page = match.currentPage;
    page.routeData._onEndReevaluating(match.originalMatch);
    _pages.add(page);
    if (notify) {
      notifyAll();
    }
  }

  Future<T?>? _addNewPage<T extends Object?>(
    RouteMatch route, {
    bool notify = true,
    int? index,
  }) {
    final topRoute = _pages.lastOrNull?.routeData;
    if (topRoute != null && topRoute._match.keepHistory == false) {
      markUrlStateForReplace();
      _removeRoute(topRoute._match, notify: false);
    }
    final data = _createRouteData<T>(route, routeData, popCompleter: Completer<T?>());
    final page = data.buildPage<T>();
    if (index != null) {
      _pages.insert(index, page);
    } else {
      _pages.add(page);
    }
    if (notify) {
      notifyAll();
    }
    return data.popped;
  }

  Future<ResolverResult> _canNavigate(
    RouteMatch route, {
    OnNavigationFailure? onFailure,
    List<RouteMatch> pendingRoutes = const [],
    bool isReevaluating = false,
  }) async {
    RouteMatch routeToCheck = route;
    final guards = <AutoRouteGuard>[
      ...root.guards,
      ...routeToCheck.guards,
    ];
    if (guards.isEmpty) {
      return SynchronousFuture(
        ResolverResult(
          continueNavigation: true,
          reevaluateNext: true,
          route: routeToCheck,
        ),
      );
    }
    bool breakOnReevaluate = false;
    for (final guard in guards) {
      if (routeToCheck.evaluatedGuards.contains(guard)) {
        routeToCheck = routeToCheck.copyWith(
          evaluatedGuards: routeToCheck.evaluatedGuards.where((e) => e != guard).toList(),
        );
        continue;
      }
      final completer = Completer<ResolverResult>();
      final resolver = NavigationResolver(
        this,
        completer,
        routeToCheck,
        pendingRoutes: pendingRoutes,
        isReevaluating: isReevaluating,
      );
      final guardEntry = GuardEntry(guard, resolver);
      activeGuardObserver._add(guardEntry);
      guard.onNavigation(resolver, this);
      final result = await completer.future;
      routeToCheck = result.route;
      breakOnReevaluate |= result.reevaluateNext;
      if (!result.continueNavigation) {
        if (onFailure != null) {
          onFailure(RejectedByGuardFailure(routeToCheck, guard));
        }
        activeGuardObserver._remove(guardEntry);
        return result.copyWith(reevaluateNext: breakOnReevaluate);
      }
      activeGuardObserver._remove(guardEntry);
    }
    return ResolverResult(
      continueNavigation: true,
      reevaluateNext: breakOnReevaluate,
      route: routeToCheck,
    );
  }

  /// Preforms pop-until finds cosponsoring route with [routes].first
  /// then pushes all [routes]
  ///
  /// if [onFailure] callback is provided, navigation errors will be passed to it
  /// otherwise they'll be thrown
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
    bool isReevaluating = false,
  }) async {
    if (isReevaluating) {
      _pages.clear();
    }
    if (routes.isNotEmpty) {
      if (!managedByWidget) {
        await _popUntilOrPushAll(
          routes,
          onFailure: onFailure,
          isReevaluating: isReevaluating,
        );
      } else {
        _onNavigate(routes);
      }
      final mayUpdateRoute = routes.last;
      final mayUpdateController = _topInnerControllerOf(mayUpdateRoute.key);
      if (mayUpdateController != null) {
        final newChildren = mayUpdateRoute.children ?? const [];
        if (mayUpdateController.managedByWidget) {
          mayUpdateController._onNavigate(newChildren);
        }
        return mayUpdateController._navigateAll(
          newChildren,
          onFailure: onFailure,
          isReevaluating: isReevaluating,
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

  /// Push the given [route] onto the navigator, and then [maybePop] all the previous
  /// routes until the [predicate] returns true.
  ///
  /// if [onFailure] callback is provided, navigation errors will be passed to it
  /// otherwise they'll be thrown
  @optionalTypeArgs
  Future<T?> pushAndPopUntil<T extends Object?>(
    PageRouteInfo route, {
    required RoutePredicate predicate,
    bool scopedPopUntil = true,
    OnNavigationFailure? onFailure,
  }) {
    if (!scopedPopUntil) {
      popUntil(predicate, scoped: false);
    }
    final scope = _findStackScope(route);
    if (scopedPopUntil) {
      scope.popUntil(predicate);
    }
    return scope._push<T>(route, onFailure: onFailure);
  }

  /// Removes last entry in stack and pushes given [path]
  /// if last entry.path == [path] page will just be updated
  ///
  /// if [includePrefixMatches] is true prefixed-matches
  /// will be added to to target destination
  /// see [RouteMatcher.matchUri]
  ///
  /// if [onFailure] callback is provided, navigation errors will be passed to it
  /// otherwise they'll be thrown
  @optionalTypeArgs
  Future<T?> replacePath<T extends Object?>(
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
      scope.router._removeLast(notify: false);
      markUrlStateForReplace();
      return scope.router._pushAllGuarded(
        scope.matches,
        onFailure: onFailure,
      );
    }
    return SynchronousFuture(null);
  }

  /// Removes last entry in stack and pushes given [path]
  @Deprecated('Use replacePath instead')
  Future<T?> replaceNamed<T extends Object?>(
    String path, {
    bool includePrefixMatches = false,
    OnNavigationFailure? onFailure,
  }) =>
      replacePath<T>(
        path,
        includePrefixMatches: includePrefixMatches,
        onFailure: onFailure,
      );

  /// Adds corresponding page to given [path] to [_pages] stack
  ///
  /// if [includePrefixMatches] is true prefixed-matches
  /// will be added to to target destination
  /// see [RouteMatcher.matchUri]
  ///
  /// if [onFailure] callback is provided, navigation errors will be passed to it
  /// otherwise they'll be thrown
  @optionalTypeArgs
  Future<T?> pushPath<T extends Object?>(
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

  /// Adds corresponding page to given [path] to [_pages] stack
  @Deprecated('Use pushPath instead')
  Future<T?> pushNamed<T extends Object?>(
    String path, {
    bool includePrefixMatches = false,
    OnNavigationFailure? onFailure,
  }) =>
      pushPath<T>(
        path,
        includePrefixMatches: includePrefixMatches,
        onFailure: onFailure,
      );

  /// Helper to pop all routes until route with [name] is found
  /// see [popUntil]
  void popUntilRouteWithName(String name, {bool scoped = true}) {
    popUntil(ModalRoute.withName(name), scoped: scoped);
  }

  /// Helper to pop all routes until route with [path] is found
  /// see [popUntil]
  void popUntilRouteWithPath(String path, {bool scoped = true}) {
    popUntil((route) {
      if ((route.settings is AutoRoutePage)) {
        return (route.settings as AutoRoutePage).routeData.match == path;
      }
      // Assuming pageless routes are either dialogs or bottomSheetModals
      // and the user set a path as in RouteSettings(name: path) when showing theme
      return route.settings.name == path;
    }, scoped: scoped);
  }
}

/// An Implementation of StackRouter used by nested
/// [AutoRouter] widgets
class NestedStackRouter extends StackRouter {
  @override
  final RouteMatcher matcher;
  @override
  final RouteCollection routeCollection;

  @override
  final bool managedByWidget;

  RouteData _routeData;

  /// Default constructor
  NestedStackRouter({
    required this.routeCollection,
    required super.key,
    required super.matchId,
    required RouteData routeData,
    this.managedByWidget = false,
    required RoutingController super.parent,
    super.onNavigate,
    super.navigatorKey,
  })  : matcher = RouteMatcher(routeCollection),
        _routeData = routeData;

  @override
  RouteData get routeData => _routeData;

  @override
  void updateRouteData(RouteData data) {
    _routeData = data;
    for (final page in _pages) {
      page.routeData._updateParentData(data);
    }
  }

  @internal

  /// pushes the initial routes to the stack
  void setupInitialRoutes() async {
    if (_routeData.hasPendingChildren) {
      final initialRoutes = List<RouteMatch>.unmodifiable(_routeData.pendingChildren);
      if (managedByWidget) {
        pendingRoutesHandler._setPendingRoutes(
          initialRoutes.map((e) => e.toPageRouteInfo()).toList(),
        );
      } else {
        _pushAllGuarded(
          initialRoutes,
          returnLastRouteCompleter: false,
        );
      }
      _routeData.pendingChildren.clear();
    } else {
      final possibleInitialRoutes = matcher.match('');
      if (possibleInitialRoutes != null) {
        _pushAllGuarded(
          possibleInitialRoutes,
          returnLastRouteCompleter: false,
        );
      }
    }
  }
}

class _RouterScopeResult<T extends RoutingController> {
  final T router;
  final List<RouteMatch> matches;

  const _RouterScopeResult(this.router, this.matches);
}

/// Holds a one-time read initial routes value
/// used by declarative routing widgets
class PendingRoutesHandler {
  List<PageRouteInfo<dynamic>>? _initialPendingRoutes;

  /// Whether [_initialPendingRoutes] is not empty
  bool get hasPendingRoutes => _initialPendingRoutes?.isNotEmpty == true;

  void _setPendingRoutes(List<PageRouteInfo>? routes) {
    _initialPendingRoutes = routes;
  }

  /// Reads [_initialPendingRoutes] without deleting it's value
  List<PageRouteInfo<dynamic>>? get peek => _initialPendingRoutes;

  /// One time read pending routes
  ///
  /// [_initialPendingRoutes] is deleted after the read
  List<PageRouteInfo<dynamic>>? get initialPendingRoutes {
    if (_initialPendingRoutes == null) return null;
    final routes = List<PageRouteInfo>.of(_initialPendingRoutes!);
    _initialPendingRoutes = null;
    return routes;
  }
}

/// Observers the current guards processing navigation event
class ActiveGuardObserver extends ValueNotifier<List<GuardEntry>> {
  /// Default controller
  ActiveGuardObserver() : super([]);

  /// Adds [guard] to the list of active guards
  void _add(GuardEntry entry) {
    value = [...value, entry];
  }

  /// Removes [guard] from the list of active guards
  void _remove(GuardEntry entry) {
    value = [...value..remove(entry)];
  }

  /// Whether there's a guard  pending completion
  bool get guardInProgress => value.isNotEmpty;

  /// returns a list of active guards
  List<AutoRouteGuard> get activeGuards => List.unmodifiable(value.map((e) => e.guard));
}

/// A class that holds a guard and it's corresponding resolver
class GuardEntry {
  /// The auto route guard
  final AutoRouteGuard guard;

  final NavigationResolver _resolver;

  /// Default constructor
  const GuardEntry(this.guard, this._resolver);
}
