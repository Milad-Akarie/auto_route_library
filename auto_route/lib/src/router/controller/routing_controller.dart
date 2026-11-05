import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/matcher/route_matcher.dart';
import 'package:auto_route/src/route/auto_route_config.dart';
import 'package:auto_route/src/router/transitions/custom_page_route.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

part '../../route/route_data.dart';
part 'auto_route_guard.dart';
part 'auto_router_delegate.dart';
part 'root_stack_router.dart';
part 'route_leave.dart';
part 'routes_restoration.dart';

/// Signature of a predicate to select [RouteData]
typedef RouteDataPredicate = bool Function(RouteData<dynamic> route);

/// Signature of a callback used by declarative
typedef OnNestedNavigateCallBack = void Function(
  List<RouteMatch<dynamic>> routes,
);

/// Signature of a callback used in declarative routing
typedef RoutesBuilder = List<PageRouteInfo> Function(
  PendingRoutesHandler handler,
);

/// Signature of a callback to report route pop events
typedef RoutePopCallBack = void Function(
  RouteMatch<dynamic> route,
  Page<Object?> page,
);

/// Signature of a callback used in declarative routing
/// to report url state changes
typedef OnNavigateCallBack = void Function(UrlState tree);

/// Signature for a builder that returns a list of [NavigatorObserver]
typedef NavigatorObserversBuilder = List<NavigatorObserver> Function();

/// An Abstraction for an object that manages
/// page navigation
abstract class RoutingController with ChangeNotifier {
  final _childControllers = <RoutingController>[];
  bool _shouldIgnorePopCompleter = false;

  /// Whether [AutoRoutePage] should await for pop-completer
  bool get ignorePopCompleters => root._shouldIgnorePopCompleter;

  @visibleForTesting
  set ignorePopCompleters(bool value) {
    root._shouldIgnorePopCompleter = value;
  }

  /// This key is passed to the router scope
  /// it's used to provide build context inside auto_route guards instead of
  /// using `navigatorKey.currentContext` because it maybe null at times
  final GlobalObjectKey<State<StatefulWidget>> globalRouterKey =
      GlobalObjectKey(UniqueKey());

  /// Holds track of the list of attached child controllers
  List<RoutingController> get childControllers => _childControllers;

  // Called on hot reload. A router that copied its routes from its parent
  // reads them again, so routes added or removed since it was built match.
  void _reassemble() {
    for (final child in _childControllers) {
      child._reassemble();
    }
  }

  // The routes of [name] in this controller's routes, if it still has
  // children after a hot reload.
  RouteCollection? _reassembledSubCollection(String name) {
    final route = routeCollection[name];
    return route != null && route.hasSubTree
        ? routeCollection.subCollectionOf(name)
        : null;
  }

  final List<AutoRoutePage<Object?>> _pages = [];

  /// The instance of [NavigationHistory] to be used by this router
  ///
  /// There's only one [NavigationHistory] instance in the whole
  /// hierarchy that's built inside of the [root] navigator
  ///
  /// sub-controllers will use that instance instead of creating their own
  NavigationHistory get navigationHistory => root.navigationHistory;

  /// See [NavigationHistory.markUrlStateForReplace]
  void markUrlStateForReplace() => navigationHistory.markUrlStateForReplace();

  bool _isMarkedForDataUpdate = false;

  /// Adds the given controller to the list of [childControllers]
  void attachChildController(RoutingController childController) {
    assert(
      !_childControllers.contains(childController),
      'This child controller is already attached.',
    );
    _childControllers.add(childController);
  }

  /// removes the given controller from the list of [childControllers]
  void removeChildController(RoutingController childController) {
    _childControllers.remove(childController);
  }

  RoutingController? _topInnerControllerOf(Key routeKey) {
    return _childControllers.lastWhereOrNull((c) => c.key == routeKey);
  }

  // The nested router of the page [data] belongs to, found by the page's
  // match id: two pages can share a route key, as two AutoTabsRouter tabs do
  // when both are children of the same parent route, and as a page does with
  // the one it replaced while that one still animates out with its own nested
  // router. A page that takes over the nested router of the page it replaced
  // takes over its match id too.
  RoutingController? _innerControllerOfPage(RouteData<Object?>? data) {
    if (data == null) return null;
    return _innerControllerOfMatch(data.matchId);
  }

  RoutingController? _innerControllerOfMatch(Key matchKey) {
    return _childControllers.lastWhereOrNull((c) => c.matchId == matchKey);
  }

  // The pages open in this router, in the shape a nested router opens from
  // its route's pending children: each holds the pages of its own nested
  // router, and a tabs router lists all its tabs, the active one last. Their
  // guards already let them open, so they aren't checked again.
  List<RouteMatch<Object?>> _openMatches() {
    final pages = _pages.map((page) => page.routeData).toList();
    if (this case final TabsRouter tabs when tabs.activeIndex < pages.length) {
      pages.add(pages.removeAt(tabs.activeIndex));
    }
    return [
      for (final data in pages)
        data.route.copyWith(
          queryParams: data._ownQueryParams,
          fragment: data._ownFragment,
          children: switch (_innerControllerOfMatch(data.matchId)) {
            null => data.pendingChildren,
            final child when child.managedByWidget => null,
            final child => child._openMatches(),
          },
          evaluatedGuards: data.route.guards,
        ),
    ];
  }

  /// Helper to access [NavigationHistory.urlState]
  UrlState get urlState => navigationHistory.urlState;

  /// Helper to access `NavigationHistory.urlState.path`
  String get currentPath => urlState.path;

  /// Helper to access `NavigationHistory.urlState.url`
  String get currentUrl => urlState.url;

  /// Notify this controller for changes then notify root controller
  /// if they're not the same
  ///
  /// if needed rebuild the url
  void notifyAll({bool forceUrlRebuild = false}) {
    notifyListeners();
    if (forceUrlRebuild || !isRouteDataActive(current)) {
      navigationHistory.rebuildUrl();
    }
    // The root hears of every change, to save the pages of nested routers
    // for state restoration even when the url stays the same.
    if (!isRoot) {
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
  }) => _getCurrentHierarchy(
    stackData,
    asPath: asPath,
    ignoreParams: ignoreParams,
    ignorePending: ignorePending,
  );

  List<HierarchySegment> _getCurrentHierarchy(
    List<RouteData<Object?>> pages, {
    required bool asPath,
    required bool ignorePending,
    required bool ignoreParams,
  }) {
    final hierarchy = <HierarchySegment>[];
    for (final data in pages) {
      final segmentName = asPath ? data.match : data.name;
      final childCtrl = _innerControllerOfPage(data);
      final childSegments = <HierarchySegment>[];
      if (childCtrl?.hasEntries == true) {
        // The child router looks up its own nested routers.
        childSegments.addAll(
          childCtrl!._getCurrentHierarchy(
            childCtrl.stackData,
            asPath: asPath,
            ignorePending: ignorePending,
            ignoreParams: ignoreParams,
          ),
        );
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
          pathParams: ignoreParams || data.params.isEmpty ? null : data.params,
          queryParams: ignoreParams || data.queryParams.isEmpty
              ? null
              : data.queryParams,
        ),
      );
    }
    return hierarchy;
  }

  /// Returns an unmodifiable lis of current pages stack data
  List<RouteData<dynamic>> get stackData =>
      .unmodifiable(_pages.map((e) => e.routeData));

  /// See [NavigationHistory.isRouteActive]
  bool isRouteActive(String routeName) {
    return navigationHistory.isRouteActive(routeName);
  }

  /// See [NavigationHistory.isRouteDataActive]
  bool isRouteDataActive(RouteData<dynamic> data) {
    return navigationHistory.isRouteDataActive(data);
  }

  /// See [NavigationHistory.isPathActive]
  bool isPathActive(String path) {
    return navigationHistory.isPathActive(path);
  }

  Future<List<ReevaluatableRouteMatch<Object?, Object?>>>
  _composeMatchesForReevaluate();

  late Key _stackKey = UniqueKey();

  RouteData<T?> _createRouteData<T>(
    RouteMatch<Object?> route,
    RouteData<Object?> parent, {
    Completer<T?>? popCompleter,
  }) {
    final created = RouteData<T>(
      popCompleter: popCompleter,
      route: route,
      router: this,
      parent: parent,
      stackKey: _stackKey,
      pendingChildren: route.children ?? [],
      type: route.type ?? root.defaultRouteType,
    );
    final takenRestorationIds = {
      for (final page in _pages)
        if (page.routeData.matchId != created.matchId) page.restorationId,
    };
    created._takeRestorationIdApartFrom(takenRestorationIds);
    for (final ctr in _childControllers) {
      if (ctr._isMarkedForDataUpdate && ctr.key == created.key) {
        ctr
          ..updateRouteData(created)
          .._isMarkedForDataUpdate = false;
      }
    }

    return created;
  }

  /// Helper to find route match
  /// See [RouteMatcher.matchByRoute]
  RouteMatch<dynamic>? match(PageRouteInfo route) {
    return matcher.matchByRoute(route);
  }

  // Reports a route no route matches to [onFailure]; without one, throws it,
  // or with [shouldThrow] false returns null.
  RouteMatch<Object?>? _matchOrReportFailure(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
    bool shouldThrow = true,
  }) {
    var match = matcher.matchByRoute(route);
    if (match != null) {
      return match;
    }
    match = matcher.buildPathTo(route);
    if (match == null) {
      final failure = _notFound(route.routeName);
      if (onFailure != null) {
        onFailure(failure);
        return null;
      }
      if (!shouldThrow) return null;
      throw FlutterError(failure.toString());
    }
    return _reuseOpenAncestors(match);
  }

  // [RouteMatcher.buildPathTo] makes up the ancestors of a route nested deeper
  // than this router, with no path params or args. Where the same ancestor is
  // already open, or about to open, take its params and args, so navigating
  // to the route keeps the parent that holds the path params it inherits.
  RouteMatch<Object?> _reuseOpenAncestors(RouteMatch<Object?> built) {
    final chain = built.flattened;
    RoutingController? controller = this;
    var pending = const <RouteMatch<Object?>>[];
    for (var i = 0; i < chain.length - 1; i++) {
      final name = chain[i].name;
      RouteMatch<Object?>? open;
      if (controller != null) {
        final data = controller.stackData.lastWhereOrNull(
          (d) => d.name == name,
        );
        open = data?.route;
        if (data != null) {
          // A nested router that isn't built yet holds its routes as pending
          // children.
          pending = data.pendingChildren;
          controller = controller._innerControllerOfMatch(data.matchId);
        }
      } else {
        open = pending.lastWhereOrNull((m) => m.name == name);
        pending = open?.children ?? const [];
      }
      if (open == null) break;
      chain[i] = chain[i].copyWith(
        stringMatch: open.stringMatch,
        segments: open.segments,
        params: open.params,
        args: open.args,
        key: open.key,
      );
    }
    return UrlState.toHierarchy(chain);
  }

  List<RouteMatch<Object?>>? _matchAllOrReportFailure(
    List<PageRouteInfo> routes, {
    OnNavigationFailure? onFailure,
    bool shouldThrow = true,
  }) {
    final matches = <RouteMatch<Object?>>[];
    for (final route in routes) {
      final match = _matchOrReportFailure(
        route,
        onFailure: onFailure,
        shouldThrow: shouldThrow,
      );
      if (match != null) {
        // Only a stack opens listed routes one above the other; a tabs router
        // shows each listed route as its own tab.
        final previous = matches.lastOrNull;
        final merged = this is StackRouter && previous != null
            ? _mergeIntoParent(previous, match)
            : null;
        if (merged != null) {
          matches
            ..removeLast()
            ..add(merged);
        } else {
          matches.add(match);
        }
      } else {
        return null;
      }
    }
    return matches;
  }

  // A route of a nested router that isn't open comes inside the parents made
  // up for it. When [next]'s made-up parent is the route [previous] opens, its
  // children join [previous]'s, so routes listed together open in one nested
  // router instead of each in its own copy of the parent.
  RouteMatch<Object?>? _mergeIntoParent(
    RouteMatch<Object?> previous,
    RouteMatch<Object?> next,
  ) {
    if (!next.autoFilled || next.name != previous.name) return null;
    final children = [...?previous.children];
    for (final child in next.children ?? const <RouteMatch<Object?>>[]) {
      final last = children.lastOrNull;
      final merged = last == null ? null : _mergeIntoParent(last, child);
      if (merged != null) {
        children
          ..removeLast()
          ..add(merged);
      } else {
        children.add(child);
      }
    }
    return previous.copyWith(children: children);
  }

  /// Whether is router is used by a declarative-routing widget
  bool get managedByWidget;

  bool _canHandleNavigation(PageRouteInfo route) {
    return routeCollection.containsKey(route.routeName);
  }

  _RouterScopeResult<T>?
  _findPathScopeOrReportFailure<T extends RoutingController>(
    String path, {
    bool includePrefixMatches = false,
    OnNavigationFailure? onFailure,
  }) {
    if (path.startsWith('/')) {
      final scope = root._absolutePathScope(
        path,
        includePrefixMatches: includePrefixMatches,
      );
      if (scope != null && scope.router is T) {
        return _RouterScopeResult(scope.router as T, scope.matches);
      }
    }
    final routers = _topMostRouter(ignorePagelessRoutes: true)
        ._buildRoutersHierarchy()
        .whereType<T>();

    for (final router in routers) {
      final matches = router.matcher.match(
        path,
        includePrefixMatches: includePrefixMatches,
      );
      if (matches != null) {
        return _RouterScopeResult(router, matches);
      }
    }
    final failure = _notFound(path);
    if (onFailure != null) {
      onFailure(failure);
    } else {
      throw FlutterError(failure.toString());
    }
    return null;
  }

  // Reports [target], with the app's routes, so the message shows the paths
  // that exist next to the one that matched nothing.
  RouteNotFoundFailure _notFound(String target) =>
      .new(target, routeTree: root.routeCollection.toTreeString());

  // Matches an absolute path from this router, the root, the way a deep link
  // is matched: a nested router's relative paths never see the leading '/',
  // so only its wild-card would take it. Then follows the open stack routers
  // whose top page is the next match, and returns the deepest of them with
  // the matches left for it.
  _RouterScopeResult<RoutingController>? _absolutePathScope(
    String path, {
    required bool includePrefixMatches,
  }) {
    final found = matcher.match(
      path,
      includePrefixMatches: includePrefixMatches,
    );
    if (found == null) return null;
    var matches = found;
    var router = this;
    // While a single match with children is left, its children go on in the
    // nested router that already shows it.
    while (true) {
      final match = matches.singleOrNull;
      final children = match?.children;
      if (match == null || children == null || children.isEmpty) break;
      final top = router.stackData.lastOrNull;
      if (top == null ||
          top.name != match.name ||
          top.match != match.stringMatch) {
        break;
      }
      final child = router._topInnerControllerOf(top.key);
      if (child is! StackRouter) break;
      router = child;
      matches = children;
    }
    return _RouterScopeResult(router, matches);
  }

  RoutingController _findScope(PageRouteInfo route) {
    return _topMostRouter(ignorePagelessRoutes: true)
        ._buildRoutersHierarchy()
        .firstWhere((r) => r._canHandleNavigation(route), orElse: () => this);
  }

  /// Pops until given [route], if it already exists in stack otherwise adds it
  /// to the stack (good for web Apps and to avoid duplicate entries).
  ///
  /// if [onFailure] callback is provided, navigation errors will be passed to
  /// it otherwise they'll be thrown
  Future<T?> navigate<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) async {
    return await _findScope(route)._navigate(route, onFailure: onFailure);
  }

  /// Pops until given [path], if it already exists in stack
  /// otherwise adds it to the stack
  ///
  /// if [includePrefixMatches] is true prefixed-matches
  /// will be added to to target destination
  /// see [RouteMatcher.matchUri]
  ///
  /// if [onFailure] callback is provided, navigation errors will be passed to
  /// it otherwise they'll be thrown
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

  Future<T?> _navigate<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) async {
    final match = _matchOrReportFailure(route, onFailure: onFailure);
    if (match != null) {
      return await _navigateAll([match], onFailure: onFailure);
    }
    return null;
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

    final routers = [this];
    if (_parent != null) {
      collectRouters(_parent!, routers);
    }
    return routers;
  }

  // should find a way to avoid this
  void _updateSharedPathData({
    Map<String, Object?> queryParams = const {},
    String fragment = '',
    bool includeAncestors = false,
  });

  /// Takes a state snapshot of the current segments
  int get stateHash =>
      const ListEquality<Object?>().hash(_addedSegments) ^ pageCount;

  /// The Identifier key of this routing controller
  Key get key;

  /// The unique identifier of the [RouteMatch] linked to this controller
  Key get matchId;

  /// The matcher used by this controller
  /// see [RouteMatcher]
  RouteMatcher get matcher;

  /// The current pages stack of this controller
  List<AutoRoutePage<dynamic>> get stack;

  RoutingController? get _parent;

  /// Whether this controller has the top-most visible page of the whole
  /// router tree, not only of its own subtree.
  bool get isTopMost => this == topMostRouter();

  /// Whether every tabs router above this controller shows the tab that
  /// holds it.
  ///
  /// The router of a tab that isn't active stays mounted but hidden, and
  /// back must not reach it.
  @internal
  bool get isInActiveTabs {
    var child = this;
    for (var parent = _parent; parent != null; parent = parent._parent) {
      if (parent is TabsRouter && parent.currentChild?.key != child.key) {
        return false;
      }
      child = parent;
    }
    return true;
  }

  /// The tabs routers above this controller, nearest first.
  @internal
  List<TabsRouter> get ancestorTabsRouters => [
    for (var parent = _parent; parent != null; parent = parent._parent)
      if (parent is TabsRouter) parent,
  ];

  /// Casts parent controller to [T]
  ///
  /// returns null if [_parent]
  T? parent<T extends RoutingController>() {
    return _parent as T?;
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

  /// Completes once the pages of every router in the app have ended their
  /// transitions: a page coming in after a push or replace, and a page
  /// leaving after a pop.
  ///
  /// Call it right after the navigation, without awaiting the navigation's
  /// own future: the future of [StackRouter.push] completes only when the
  /// pushed page is popped. For example, to open a bottom sheet once the page
  /// has come in, since a sheet opened while the page still moves can close
  /// at once:
  ///
  /// ```dart
  /// unawaited(context.router.push(const DetailsRoute()));
  /// await context.router.waitForTransitions();
  /// if (context.mounted) showModalBottomSheet(context: context, builder: ...);
  /// ```
  ///
  /// It checks after every frame, from the frame after the call, so a page
  /// pushed just before the call has started to come in. A push still
  /// waiting on an asynchronous guard is not waited for, and neither are
  /// dialogs and other routes pushed without a page. With nothing moving, it
  /// completes after the next frame.
  Future<void> waitForTransitions() async {
    do {
      await SchedulerBinding.instance.endOfFrame;
    } while (_hasTransitionIn(root));
  }

  // Whether a page of [router], or of a router nested in it, is coming in or
  // leaving, or a push to it is about to add its page.
  static bool _hasTransitionIn(RoutingController router) {
    if (router case final StackRouter stack) {
      stack._leavingAnimations.removeWhere(
        (animation) => !animation.isAnimating,
      );
      if (stack._landingPushes.isNotEmpty ||
          stack._leavingAnimations.isNotEmpty) {
        return true;
      }
      if (stack._pages.any(
        (page) => page.routeData.animation?.isAnimating ?? false,
      )) {
        return true;
      }
    }
    return router._childControllers.any(_hasTransitionIn);
  }

  /// Returns parent route as [StackRouter]
  StackRouter? get parentAsStackRouter => parent();

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
  RouteData<dynamic>? get currentChild;

  /// Returns [currentChild] if it's rendered
  /// otherwise returns parent [routeData]
  RouteData<dynamic> get current;

  /// The top-most rendered route
  RouteData<dynamic> get topRoute => _topMostRouter().current;

  /// The top-most rendered or pending route match
  RouteMatch<dynamic> get topMatch => topRoute.topMatch;

  /// The data of the parent route
  RouteData<dynamic> get routeData;

  /// Updates the value of [routeData]
  void updateRouteData(RouteData<dynamic> data);

  /// The list of routes consumed by this controller
  RouteCollection get routeCollection;

  /// The top-most visible page
  AutoRoutePage<dynamic>? get topPage => _topMostRouter()._pages.lastOrNull;

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
      (c) => c.routeData.name == routeName,
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
  Future<bool> maybePopTop<T extends Object?>([T? result]) =>
      _topMostRouter().maybePop(result);

  /// Clients can either pop their own [_pages] stack
  /// or defer the call to a parent controller
  ///
  /// see [Navigator.pop(context)] for more details
  @optionalTypeArgs
  void pop<T extends Object?>([T? result]);

  /// Calls [pop] on the controller with the top-most visible page
  @optionalTypeArgs
  void popTop<T extends Object?>([T? result]) => _topMostRouter().pop(result);

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
  bool childrenCanPop({bool ignorePagelessRoutes = false}) {
    return _childControllers.any(
      (c) => c.canPop(
        ignorePagelessRoutes: ignorePagelessRoutes,
        ignoreParentRoutes: true,
      ),
    );
  }

  /// returns true if the active child controller can pop
  bool activeRouterCanPop({bool ignorePagelessRoutes = false}) {
    final innerRouter = _innerControllerOfPage(currentChild);
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
  List<RouteMatch<dynamic>> get currentSegments {
    final currentData = currentChild;
    final segments = <RouteMatch<Object?>>[];
    if (currentData != null) {
      segments.add(currentData.route);
      final childCtrl = _innerControllerOfPage(currentData);
      if (childCtrl?.hasEntries == true) {
        segments.addAll(childCtrl!.currentSegments);
      } else if (currentData.pendingChildren case [..., final last]) {
        segments.addAll(last.flattened);
      }
    }
    return segments;
  }

  /// this is an indicator for controller state changes, every controller's
  /// state is considered updated if it's stateHash or any of it's children's
  /// stateHash changes
  List<RouteMatch<Object?>> get _addedSegments {
    final currentData = currentChild;
    final segments = <RouteMatch<Object?>>[];
    if (currentData != null) {
      segments.add(currentData.route);
      final childCtrl = _innerControllerOfPage(currentData);
      if (childCtrl?.hasEntries == true) {
        segments.addAll(childCtrl!._addedSegments);
      }
    }
    return segments;
  }

  /// Finds match of [path] then returns a route-able entity
  PageRouteInfo? buildPageRoute(
    String? path, {
    bool includePrefixMatches = true,
  }) {
    if (path == null) return null;
    return matcher
        .match(path, includePrefixMatches: includePrefixMatches)
        ?.firstOrNull
        ?.toPageRouteInfo();
  }

  /// Finds matches of [path] then returns a list of route-able entities
  List<PageRouteInfo>? buildPageRoutesStack(
    String? path, {
    bool includePrefixMatches = true,
  }) {
    if (path == null) return null;
    return matcher
        .match(path, includePrefixMatches: includePrefixMatches)
        ?.map((m) => m.toPageRouteInfo())
        .toList();
  }

  @override
  String toString() => '${routeData.name} Router';

  Future<T?> _navigateAll<T extends Object?>(
    List<RouteMatch<Object?>> routes, {
    OnNavigationFailure? onFailure,
    bool isReevaluating = false,
  });

  Future<void> _navigateAllRoutes(
    List<PageRouteInfo> routes, {
    OnNavigationFailure? onFailure,
  }) {
    final matches = _matchAllOrReportFailure(routes, onFailure: onFailure);
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
  /// Default constructor
  new({
    required RouteCollection routeCollection,
    required this.key,
    required this._routeData,
    required this.preload,
    required this.matchId,
    this.homeIndex = -1,
    this.backThroughHistory = false,
    this._parent,
  }) : _routeCollection = routeCollection,
       _matcher = RouteMatcher(routeCollection);
  @override
  final RoutingController? _parent;
  @override
  final Key key;
  @override
  final Key matchId;
  RouteCollection _routeCollection;
  RouteMatcher _matcher;

  @override
  RouteCollection get routeCollection => _routeCollection;

  @override
  RouteMatcher get matcher => _matcher;

  @override
  void _reassemble() {
    if (_parent?._reassembledSubCollection(_routeData.name)
        case final collection?) {
      _routeCollection = collection;
      _matcher = RouteMatcher(collection);
    }
    super._reassemble();
  }

  // A child route of this router's parent route that is not one of the tabs
  // has no place here: report it, as any route no router can show is, instead
  // of leaving the tabs as they are without a word.
  @override
  Future<T?> _navigate<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) async {
    final match = _matchOrReportFailure(route, onFailure: onFailure);
    if (match == null) return null;
    if (_pages.isNotEmpty && _tabIndexOf(match) == -1) {
      if (onFailure != null) {
        onFailure(RouteNotFoundFailure(route.routeName));
        return null;
      }
      throw FlutterError(
        'Can not navigate to ${route.routeName}: it is not one of the tabs '
        'of the tabs router of '
        '${routeData.name}. Add it to the routes of its AutoTabsRouter, or '
        'show it in a router of its own.',
      );
    }
    return await _navigateAll([match], onFailure: onFailure);
  }

  RouteData<Object?> _routeData;
  int _activeIndex = 0;
  int? _previousIndex;

  /// The index to pop from
  ///
  /// if activeIndex != homeIndex
  /// set activeIndex to homeIndex
  /// else pop parent
  final int homeIndex;

  /// Whether back shows the tabs visited before the active one, the latest
  /// first, before it leaves the tabs.
  ///
  /// Back is [maybePop] and [pop], which Android's back key and the
  /// predictive back gesture reach. While a tab is left to go back to, the
  /// app tells Android it handles back, so Android 13 and later don't close
  /// the app instead. Defaults to false.
  ///
  /// Each tab is in the history once, where it was left last: after tabs 0,
  /// 1, 0 and 2, back shows 0, then 1. A tab whose guards keep it out is
  /// skipped. Once the history is gone through, back goes on as it would
  /// without it: to the [homeIndex] tab when there is one and it isn't
  /// active, else out of the tabs.
  ///
  /// The history lives as long as this router and is not restored with
  /// the app's state. When the tabs change, it keeps the tabs still there.
  final bool backThroughHistory;

  // The tabs shown before the active one, the latest last, each once.
  final _tabHistory = <int>[];

  // Whether back stays inside these tabs, by showing another one.
  bool get _doesTakeBack =>
      (backThroughHistory && _tabHistory.isNotEmpty) ||
      (homeIndex != -1 && _activeIndex != homeIndex);

  /// Called to preload a page before other navigation events occur if it
  /// returns true, the page has been preloaded, otherwise we assume it's
  /// already loaded
  bool Function(int index) preload;

  @override
  RouteData<dynamic> get routeData => _routeData;

  @override
  void updateRouteData(RouteData<dynamic> data) {
    _routeData = data;
    for (final page in _pages) {
      page.routeData._parent = data;
    }
  }

  @override
  RouteData<dynamic> get current {
    return currentChild ?? routeData;
  }

  @override
  RouteData<dynamic>? get currentChild {
    return _pages.elementAtOrNull(_activeIndex)?.routeData;
  }

  /// The index of active page
  int get activeIndex => _activeIndex;

  /// The index of previous active page
  int? get previousIndex => _previousIndex;

  /// Updates [_activeIndex] and triggers a rebuild
  ///
  /// The tab at [index] shows only once the guards of its route let it in.
  /// When a guard decides later, the current tab stays active until then,
  /// and the change always notifies once it happens.
  void setActiveIndex(int index, {bool notify = true}) {
    assert(
      index >= 0 && index < _pages.length,
      'Tab index $index is out of range for ${_pages.length} tabs.',
    );
    // A change waits on the tab's guards when it has any; nothing here waits
    // for it.
    if (_changeTab(index, notify: notify) case final Future<void> change) {
      unawaited(change);
    }
  }

  // The latest change of the active tab, and the tab of one whose guards are
  // still deciding, with whether it happens.
  int _tabChanges = 0;
  int? _pendingTab;
  Future<_TabChange>? _pendingChange;

  // Every change of the active tab goes through here: setActiveIndex, which
  // the tabs views call too, back to a tab, and navigating to a tab. A change
  // that is not [remember]ed, such as one made by back, adds nothing to the
  // tab history.
  //
  // The tab shows once the guards of its route let it in. [route] is the
  // route a navigation opens the tab with; the tab's page is then updated
  // with it, and its nested router navigates to its children. Answers how
  // the change ended: at once when every guard answers at once, otherwise
  // once they have. A change to another tab made meanwhile replaces one
  // still waiting for its guards.
  FutureOr<_TabChange> _changeTab(
    int index, {
    bool notify = true,
    RouteMatch<Object?>? route,
    OnNavigationFailure? onFailure,
    bool remember = true,
  }) {
    if (_activeIndex == index) return _TabChange.done;
    // A view asks again for the tab it moved to while its guards decide.
    if (route == null && _pendingTab == index) return _pendingChange!;
    final change = ++_tabChanges;
    final match = route ?? _pages[index].routeData._route;
    final checked = _checkTabGuards(match, onFailure: onFailure);
    if (checked is ResolverResult) {
      return _endTabChange(
        change,
        index,
        match,
        checked,
        notify: notify,
        update: route != null,
        onFailure: onFailure,
        remember: remember,
      );
    }
    _pendingTab = index;
    // A view that moved to the tab, e.g. a page view swiped to it, shows the
    // active one until the guards let the tab in.
    if (notify) notifyListeners();
    return _pendingChange = checked.then(
      (result) => _endTabChange(
        change,
        index,
        match,
        result,
        update: route != null,
        onFailure: onFailure,
        remember: remember,
      ),
    );
  }

  _TabChange _endTabChange(
    int change,
    int index,
    RouteMatch<Object?> match,
    ResolverResult result, {
    bool notify = true,
    bool update = false,
    OnNavigationFailure? onFailure,
    bool remember = true,
  }) {
    if (_isDisposed || change != _tabChanges) return .replaced;
    _pendingTab = null;
    _pendingChange = null;
    if (!result.continueNavigation) {
      // A view that moved to the tab goes back to the active one.
      if (notify) notifyListeners();
      return .rejected;
    }
    // A guard may have overridden the route, e.g. its args.
    final updated = update || !identical(result.route, match)
        ? _updateTabPage(index, result.route)
        : null;
    final didPreload = preload(index);
    if (backThroughHistory) {
      _tabHistory
        ..remove(index)
        ..remove(_activeIndex);
      if (remember) _tabHistory.add(_activeIndex);
    }
    _previousIndex = _activeIndex;
    _activeIndex = index;
    if (notify) {
      if (didPreload && SchedulerBinding.instance.schedulerPhase != .idle) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          // The tabs may be disposed by the end of the frame.
          if (!_isDisposed) notifyAll();
        });
      } else {
        notifyAll();
      }
    }
    if (updated != null) _navigateInsideTab(updated, onFailure: onFailure);
    return .done;
  }

  // Asks the guards of the tab [route] opens whether it may show, the way a
  // stack asks before it shows a page. The app's global guards, in
  // RootStackRouter.guards, are for stack routes only. Answers at once when
  // every guard does, so a tab change that no guard delays stays
  // synchronous.
  FutureOr<ResolverResult> _checkTabGuards(
    RouteMatch<Object?> route, {
    OnNavigationFailure? onFailure,
    int from = 0,
  }) {
    final guards = route.guards;
    if (from == guards.length) {
      return ResolverResult(
        continueNavigation: true,
        reevaluateNext: true,
        route: route,
      );
    }
    final guard = guards[from];
    final router = _guardRouter;
    final resolver = NavigationResolver(router, Completer(), route);
    final entry = GuardEntry(guard, resolver);
    router.activeGuardObserver._add(entry);
    FutureOr<ResolverResult> onResult(ResolverResult result) {
      router.activeGuardObserver._remove(entry);
      if (!result.continueNavigation) {
        onFailure?.call(RejectedByGuardFailure(result.route, guard));
        return result;
      }
      return _checkTabGuards(
        result.route,
        onFailure: onFailure,
        from: from + 1,
      );
    }

    final checking = resolver.checkGuard(guard, router);
    if (resolver._result case final result?) {
      checking.ignore();
      return onResult(result);
    }
    return checking.then(onResult);
  }

  // The stack router guards of the tabs get, the nearest one above them.
  StackRouter get _guardRouter {
    for (var parent = _parent; parent != null; parent = parent._parent) {
      if (parent is StackRouter) return parent;
    }
    return root;
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  List<AutoRoutePage<dynamic>> get stack => .unmodifiable(_pages);

  AutoRoutePage<Object?>? get _activePage {
    return _pages.isEmpty ? null : _pages[_activeIndex];
  }

  @override
  RoutingController _topMostRouter({bool ignorePagelessRoutes = false}) {
    final innerRouter = _innerControllerOfPage(_activePage?.routeData);
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
    final hasShownTab = _hasShownTabOnBack();
    if (hasShownTab is bool) {
      return hasShownTab ? SynchronousFuture(true) : _maybePopParent(result);
    }
    return hasShownTab.then(
      (wasShown) => wasShown ? true : _maybePopParent<T>(result),
    );
  }

  Future<bool> _maybePopParent<T extends Object?>(T? result) {
    if (_parent != null) {
      return _parent!.maybePop(result);
    }
    return SynchronousFuture(false);
  }

  @override
  @optionalTypeArgs
  void pop<T extends Object?>([T? result]) {
    void popParentUnless({required bool shown}) {
      if (!shown) _parent?.pop(result);
    }

    final hasShownTab = _hasShownTabOnBack();
    if (hasShownTab is bool) {
      popParentUnless(shown: hasShownTab);
    } else {
      unawaited(
        hasShownTab.then((wasShown) => popParentUnless(shown: wasShown)),
      );
    }
  }

  // Shows the tab back goes to: the latest in the tab history, else the
  // home tab. Answers whether it showed one; false when there is none, or
  // when the guards of the home tab, and of every tab in the history, keep
  // theirs out. Back then goes on as it would from the home tab.
  FutureOr<bool> _hasShownTabOnBack() {
    final isFromHistory = backThroughHistory && _tabHistory.isNotEmpty;
    final FutureOr<_TabChange> change;
    if (isFromHistory) {
      change = _changeTab(_tabHistory.removeLast(), remember: false);
    } else if (homeIndex != -1 && _activeIndex != homeIndex) {
      change = _changeTab(homeIndex, remember: false);
    } else {
      return false;
    }
    FutureOr<bool> hasShownNext(_TabChange outcome) {
      if (outcome != .rejected) return true;
      return isFromHistory ? _hasShownTabOnBack() : false;
    }

    return change is _TabChange
        ? hasShownNext(change)
        : change.then(hasShownNext);
  }

  /// Pushes given [routes] to [_pages] stack
  /// after match validation and deciding initial index
  void setupRoutes(List<PageRouteInfo>? routes) {
    final routesToPush = _resolveRoutes(routes);
    // Tabs restored after the app was ended each come with their own stack.
    // The last pending one is the active tab.
    for (final pending in _routeData.pendingChildren) {
      final index = routesToPush.indexWhere((r) => r.key == pending.key);
      if (index != -1) routesToPush[index] = pending;
    }
    final outgoing = _routeData.hasPendingChildren
        ? null
        : _outgoingTabsRouter();
    final preMatchedRoute = switch (_routeData.pendingChildren) {
      [..., final last] => last,
      _ => outgoing?._activePage?.routeData.route,
    };
    var guardedIndex = -1;
    Future<ResolverResult>? guarding;
    if (preMatchedRoute != null) {
      final correspondingRouteIndex = routesToPush.indexWhere(
        (r) => r.key == preMatchedRoute.key,
      );
      // A tab named by a url, a navigation or a restore shows once the guards
      // of its route let it in, and the first tab shows meanwhile or instead.
      // The first tab shows without asking its guards: the tabs must show
      // one, so it's kept out by guarding the route that holds the tabs.
      final checked =
          correspondingRouteIndex <= 0 || !_routeData.hasPendingChildren
          ? null
          : _checkTabGuards(preMatchedRoute);
      if (checked is Future<ResolverResult>) {
        guardedIndex = correspondingRouteIndex;
        guarding = checked;
      } else if (correspondingRouteIndex != -1 &&
          checked?.continueNavigation != false) {
        routesToPush[correspondingRouteIndex] =
            checked?.route ?? preMatchedRoute;
        _previousIndex = _activeIndex;
        _activeIndex = correspondingRouteIndex;
      }
    }

    if (outgoing != null) {
      _tabHistory.addAll(_historyOf(outgoing._tabHistoryNames, routesToPush));
    }
    if (routesToPush.isNotEmpty) {
      _pushAll(routesToPush, isFromDefault: routes == null);
    }
    _routeData.pendingChildren.clear();
    if (guarding != null) {
      final index = guardedIndex;
      final match = preMatchedRoute!;
      final change = ++_tabChanges;
      _pendingTab = index;
      _pendingChange = guarding.then((result) {
        // The tab takes the first one's place in the url.
        if (result.continueNavigation && change == _tabChanges) {
          markUrlStateForReplace();
        }
        return _endTabChange(change, index, match, result, update: true);
      });
    }
    // A host opened by a url that names no tab, such as '/tabs' when no tab is
    // initial, shows its first tab. The url names that tab too, in place of
    // the host's own entry, so going back to that entry shows it. The router
    // is set up while the app builds, after the Router took the frame's url
    // to report, so the new url is reported on its own after the frame.
    if (_pages.isNotEmpty &&
        navigationHistory.isRouteDataActive(routeData) &&
        !navigationHistory.isRouteDataActive(current)) {
      navigationHistory.onNewUrlState(
        UrlState.fromSegments(root.currentSegments, shouldReplace: true),
        notify: false,
      );
      SchedulerBinding.instance.addPostFrameCallback((_) {
        root._lazyRootDelegate?._reportUrlInPlace();
      });
    }
  }

  // When a widget above AutoTabsRouter rebuilds it from scratch, the new
  // router is set up before the outgoing one with the same key is disposed,
  // so the outgoing router still knows which tab was active.
  TabsRouter? _outgoingTabsRouter() {
    return _parent?.childControllers.whereType<TabsRouter>().lastWhereOrNull(
      (c) => c != this && c.key == key,
    );
  }

  void _pushAll(
    List<RouteMatch<Object?>> routes, {
    required bool isFromDefault,
  }) {
    for (final route in routes) {
      final data = _createRouteData<Object?>(route, routeData);
      try {
        _pages.add(data.buildPage());
        // A page that needs args it can't get is reported with the reason.
        // That is the error to catch.
      } on MissingRequiredParameterError catch (e, stackTrace) {
        if (isFromDefault) {
          // The new error carries the original message and stack trace.
          Error.throwWithStackTrace(
            FlutterError(
              'Can not automatically navigate to ${route.name} because it '
              'has required parameters. '
              'Routes must be added manually to AutoTabsRouter'
              '\n${e.message}',
            ),
            stackTrace,
          );
        }
        rethrow;
      }
    }
  }

  @override
  Future<List<ReevaluatableRouteMatch<Object?, Object?>>>
  _composeMatchesForReevaluate() async {
    final matches = <ReevaluatableRouteMatch<Object?, Object?>>[];
    for (final page in stack) {
      final match = page.routeData._route;
      final ReevaluatableRouteMatch<Object?, Object?> reMatch;
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

  List<RouteMatch<Object?>> _resolveRoutes(List<PageRouteInfo>? routes) {
    final List<PageRouteInfo> routesToUse;
    if (routes != null) {
      routesToUse = routes;
    } else {
      routesToUse = routeCollection.routes
          .where((e) => e is! RedirectRoute)
          .map((e) => PageRouteInfo(e.name))
          .toList();
    }
    return _matchAllOrReportFailure(routesToUse)!;
  }

  /// Resets [_pages] stack with given [routes]
  /// and sets `previousActiveRoute` as active index if provided
  void replaceAll(List<PageRouteInfo>? routes, int fromIndex) {
    final routesToPush = _resolveRoutes(routes);
    final previousActiveRoute = stackData[fromIndex];
    final previousPages = List.of(_pages);
    final previousHistory = _tabHistoryNames;

    _pages.clear();
    for (final route in routesToPush) {
      // A tab whose route is unchanged keeps its page, so its widget state
      // and nested router survive.
      final keptPage = previousPages.firstWhereOrNull(
        (p) => _isSameTab(p.routeData.route, route),
      );
      if (keptPage != null) {
        previousPages.remove(keptPage);
        _pages.add(keptPage);
      } else {
        _pushAll([route], isFromDefault: routes == null);
      }
    }
    final keptMatchIds = _pages.map((p) => p.routeData.matchId).toSet();
    _childControllers.removeWhere((c) => !keptMatchIds.contains(c.matchId));
    var targetIndex = routesToPush.indexWhere(
      (r) => r.name == previousActiveRoute.name,
    );
    if (targetIndex == -1) {
      targetIndex = homeIndex == -1 ? 0 : homeIndex;
    }
    // Set directly, not through setActiveIndex: the old index points into the
    // old routes, so it can't be preloaded or reported to observers as the
    // previous tab. Each tabs view loads the active tab when it rebuilds with
    // the new routes.
    _activeIndex = targetIndex;
    _tabHistory
      ..clear()
      ..addAll(_historyOf(previousHistory, routesToPush));
  }

  List<String> get _tabHistoryNames => [
    for (final index in _tabHistory) _pages[index].routeData.name,
  ];

  // The tab history over [routes] that [names] give, found by name as the
  // active tab is: the tabs still there, each once, without the active one.
  List<int> _historyOf(List<String> names, List<RouteMatch<Object?>> routes) =>
      {for (final name in names) routes.indexWhere((r) => r.name == name)}
          .where((index) => index != -1 && index != _activeIndex)
          .toList();

  bool _isSameTab(RouteMatch<Object?> a, RouteMatch<Object?> b) =>
      a.key == b.key &&
      a.args == b.args &&
      a.params == b.params &&
      a.queryParams == b.queryParams;

  @override
  Future<T?> _navigateAll<T extends Object?>(
    List<RouteMatch<Object?>> routes, {
    OnNavigationFailure? onFailure,
    bool isReevaluating = false,
  }) async {
    final routesToProcess = isReevaluating ? routes : routes.reversed.take(1);
    for (final mayUpdateRoute in routesToProcess) {
      final pageToUpdateIndex = _tabIndexOf(mayUpdateRoute);

      if (pageToUpdateIndex != -1) {
        if (!isReevaluating && _activeIndex != pageToUpdateIndex) {
          _changeTab(
            pageToUpdateIndex,
            route: mayUpdateRoute,
            onFailure: onFailure,
          );
        } else {
          final shouldNotify =
              mayUpdateRoute != _pages[pageToUpdateIndex].routeData._route;
          final routeToBeUpdated = _updateTabPage(
            pageToUpdateIndex,
            mayUpdateRoute,
          );
          if (shouldNotify) {
            notifyAll();
          }
          _navigateInsideTab(
            routeToBeUpdated,
            onFailure: onFailure,
            isReevaluating: isReevaluating,
          );
        }
      }
      if (!isReevaluating && pageToUpdateIndex == -1) {
        _updateSharedPathData(
          queryParams: mayUpdateRoute.queryParams.rawMap,
          fragment: mayUpdateRoute.fragment,
        );
      }
    }

    return null;
  }

  // Puts [mayUpdateRoute] in the page of the tab at [index], and answers the
  // route the page now holds.
  RouteMatch<Object?> _updateTabPage(
    int index,
    RouteMatch<Object?> mayUpdateRoute,
  ) {
    final routeToBeUpdated = mayUpdateRoute.withId(
      _pages[index].routeData._route.id,
    );
    for (final ctr in _childControllers) {
      if (ctr.matchId == _pages[index].routeData.matchId) {
        ctr._isMarkedForDataUpdate = true;
      }
    }

    if (mayUpdateRoute is ReevaluatableRouteMatch) {
      _pages[index] = mayUpdateRoute.currentPage;
    } else {
      final data = _createRouteData<Object?>(routeToBeUpdated, routeData);
      _pages[index] = data.buildPage();
    }
    return routeToBeUpdated;
  }

  // Navigates the nested router of the tab holding [route] to its children.
  void _navigateInsideTab(
    RouteMatch<Object?> route, {
    OnNavigationFailure? onFailure,
    bool isReevaluating = false,
  }) {
    // By match id: a tab sharing its route with another has its own nested
    // router.
    final mayUpdateController = _innerControllerOfMatch(route.id);
    if (mayUpdateController != null) {
      final newRoutes = route.children ?? const [];
      unawaited(
        mayUpdateController._navigateAll(
          newRoutes,
          onFailure: onFailure,
          isReevaluating: isReevaluating,
        ),
      );
    }
  }

  // The tab [route] opens, or -1. Two tabs share a route when both are
  // children of the same parent route, each with its own nested router; the
  // one meant holds the route's first child, open or waiting to open.
  int _tabIndexOf(RouteMatch<Object?> route) {
    final tabs = [
      for (var i = 0; i < _pages.length; i++)
        if (_pages[i].routeKey == route.key) i,
    ];
    if (tabs.length < 2) return tabs.firstOrNull ?? -1;
    final childName = route.children?.firstOrNull?.name;
    bool doesHoldChild(int index) {
      final data = _pages[index].routeData;
      final pageNames =
          _innerControllerOfMatch(data.matchId)?.stackData.map((d) => d.name) ??
          data.route.children?.map((c) => c.name) ??
          const <String>[];
      return pageNames.contains(childName);
    }

    final holding = tabs.where(doesHoldChild).toList();
    final meant = holding.isEmpty ? tabs : holding;
    return meant.contains(_activeIndex) ? _activeIndex : meant.first;
  }

  /// If page corresponding with [index]
  /// has an attached [StackRouter] returns it
  /// otherwise returns null
  StackRouter? stackRouterOfIndex(int index) {
    if (_childControllers.isEmpty) {
      return null;
    }
    final pageMatchId = _pages[index].routeData.matchId;
    final innerRouter = _innerControllerOfMatch(pageMatchId);
    if (innerRouter is StackRouter) {
      return innerRouter;
    }
    return null;
  }

  @override
  bool canPop({
    bool ignoreChildRoutes = false,
    bool ignoreParentRoutes = false,
    bool ignorePagelessRoutes = false,
  }) {
    if (!ignoreChildRoutes) {
      final innerRouter = _innerControllerOfPage(_activePage?.routeData);
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
    Map<String, Object?> queryParams = const {},
    String fragment = '',
    bool includeAncestors = false,
  }) {
    final newData = _pages[activeIndex].routeData;
    final route = newData.route;
    newData._updateRoute(
      route.copyWith(queryParams: Parameters(queryParams), fragment: fragment),
    );
    if (includeAncestors && _parent != null) {
      _parent!._updateSharedPathData(
        queryParams: queryParams,
        fragment: fragment,
      );
    }
  }

  @override
  bool get managedByWidget => false;
}

/// An implementation of a [RoutingController] that handles stack navigation
abstract class StackRouter extends RoutingController {
  /// Default constructor
  new({
    required this.key,
    required this.matchId,
    OnNestedNavigateCallBack? onNavigate,
    this._parent,
    GlobalKey<NavigatorState>? navigatorKey,
  }) : _navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>(),
       _onNavigateCallback = onNavigate;
  @override
  final RoutingController? _parent;
  @override
  final Key key;

  @override
  final Key matchId;

  final GlobalKey<NavigatorState> _navigatorKey;
  final OnNestedNavigateCallBack? _onNavigateCallback;

  /// The pending routes handler for this controller
  @internal
  late final pendingRoutesHandler = PendingRoutesHandler();

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
    pagelessRoutesObserver.dispose();
    activeGuardObserver.dispose();
  }

  // Whether [dispose] was called; a navigation that resumes after awaiting a
  // guard stops here, since the router's page left the stack meanwhile.
  bool _isDisposed = false;

  // Pushes that no guard checks, from the call until their page is added a
  // microtask later. A pop called meanwhile waits for them, so it pops the
  // page the caller just pushed rather than the one below it.
  final _landingPushes = <Future<void>>{};

  // The animations of pages the navigator popped, while they leave the
  // screen; see [waitForTransitions].
  final _leavingAnimations = <Animation<Object?>>{};

  void _addLeavingAnimation(Animation<Object?> animation) {
    if (!animation.isAnimating) return;
    _leavingAnimations.add(animation);
    void listener(AnimationStatus _) {
      if (animation.isAnimating) return;
      animation.removeStatusListener(listener);
      _leavingAnimations.remove(animation);
    }

    animation.addStatusListener(listener);
  }

  /// Whether a reevaluation is in progress
  bool _isReevaluating = false;

  // The pages as the last report of leaves saw them, bottom first.
  var _pagesAtLastLeaveReport = <AutoRoutePage<Object?>>[];

  // How the pages taken off the stack since the last report left, where the
  // change says it; others are told from the change itself.
  final _leaveKinds = <RouteData<Object?>, RouteLeaveKind>{};

  // While above 0, a reevaluation takes pages off and puts back the ones its
  // guards keep, so leaves wait for its end.
  var _leaveReportHolds = 0;

  void _markLeaving(
    Iterable<AutoRoutePage<Object?>> pages,
    RouteLeaveKind kind,
  ) {
    for (final page in pages) {
      _leaveKinds.putIfAbsent(page.routeData, () => kind);
    }
  }

  Future<T> _holdingLeaveReports<T>(Future<T> Function() change) async {
    _leaveReportHolds++;
    try {
      return await change();
    } finally {
      _leaveReportHolds--;
      _reportLeaves();
    }
  }

  @override
  void notifyListeners() {
    _reportLeaves();
    super.notifyListeners();
  }

  // Tells each page that left the stack since the last report how it left,
  // and the page that was on top that a new page now covers it. A page taken
  // off with no recorded kind left by a pop when it was on top and nothing
  // took its place, was replaced when a new page did, and was removed when it
  // was below the top. A page that a new page of the same route takes over,
  // as a navigation to the route already shown does, stays on screen and
  // hasn't left.
  void _reportLeaves() {
    if (_leaveReportHolds > 0 || _isDisposed) return;
    final before = [for (final page in _pagesAtLastLeaveReport) page.routeData];
    final now = [for (final page in _pages) page.routeData];
    final takenOver = {
      for (final page in _pages)
        if (!before.contains(page.routeData)) page.routeKey,
    };
    final previousPages = _pagesAtLastLeaveReport;
    _pagesAtLastLeaveReport = List.of(_pages);
    final kinds = Map.of(_leaveKinds);
    _leaveKinds.clear();
    final oldTop = before.lastOrNull;
    if (oldTop == null) return;
    final stillShown = now.toSet();
    final isNewTopNew = switch (now.lastOrNull) {
      final newTop? => !before.contains(newTop),
      null => false,
    };
    final leaves = <(RouteData<Object?>, RouteLeaveKind)>[
      for (final page in previousPages.reversed)
        if (!stillShown.contains(page.routeData) &&
            !takenOver.contains(page.routeKey))
          (
            page.routeData,
            kinds[page.routeData] ??
                switch (page.routeData == oldTop) {
                  true when isNewTopNew => .replaced,
                  true => .popped,
                  false => .removed,
                },
          ),
      if (stillShown.contains(oldTop) && isNewTopNew) (oldTop, .covered),
    ];
    for (final (data, kind) in leaves) {
      data._reportLeave(kind);
    }
  }

  /// Re-builds all routes in stack and reevaluate guarded
  /// once by re-visiting the onNavigation method when evaluation logic changes
  ///
  /// e.g when the user is no longer authenticated
  /// and there are auth-protected routes in the stack
  Future<void> reevaluateGuards() async {
    final composed = await _composeMatchesForReevaluate();
    if (_isDisposed) return;
    // A page removed while the stack was composed, e.g. by a replaceAll called
    // right after the listenable changed, stays removed.
    final matches = composed
        .where((match) => _pages.contains(match.currentPage))
        .toList();
    if (matches.isNotEmpty && !_isReevaluating) {
      _isReevaluating = true;
      await _navigateAll(matches, isReevaluating: true);
      _isReevaluating = false;
    }
    if (_isDisposed) return;
    notifyAll();
  }

  @override
  Future<List<ReevaluatableRouteMatch<Object?, Object?>>>
  _composeMatchesForReevaluate() async {
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

      final result = await resolver.checkGuard(entry.guard, this);
      if (result.continueNavigation) {
        alreadyEvaluated
            .putIfAbsent(result.route.id, () => [])
            .add(entry.guard);
      }
    }

    final matches = <ReevaluatableRouteMatch<Object?, Object?>>[];
    for (final page in stack) {
      var match = page.routeData._route;
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
      if (stackData.any((e) => e._route.id == match.id)) {
        matches.add(
          ReevaluatableRouteMatch(currentPage: page, originalMatch: match),
        );
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
  bool canPop({
    bool ignoreChildRoutes = false,
    bool ignoreParentRoutes = false,
    bool ignorePagelessRoutes = false,
  }) {
    if (_pages.length > 1 || (!ignorePagelessRoutes && hasPagelessTopRoute)) {
      return true;
    }

    if (!ignoreChildRoutes && _pages.isNotEmpty) {
      final innerRouter = _innerControllerOfPage(_pages.last.routeData);
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
  RouteData<dynamic> get current => currentChild ?? routeData;

  @override
  RouteData<dynamic>? get currentChild {
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
    assert(navigator != null, 'The navigator of this router is not mounted.');
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
    assert(navigator != null, 'The navigator of this router is not mounted.');
    return navigator!.push(route);
  }

  @override
  RoutingController _topMostRouter({bool ignorePagelessRoutes = false}) {
    if (_childControllers.isNotEmpty &&
        (ignorePagelessRoutes || !hasPagelessTopRoute)) {
      final innerRouter = _innerControllerOfPage(currentChild);
      if (innerRouter != null) {
        return innerRouter._topMostRouter(
          ignorePagelessRoutes: ignorePagelessRoutes,
        );
      }
    }
    return this;
  }

  @override
  RouteData<dynamic> get topRoute =>
      _topMostRouter(ignorePagelessRoutes: true).current;

  /// Whether the top-most route of this controller is page-less
  bool get hasPagelessTopRoute => pagelessRoutesObserver.hasPagelessTopRoute;

  @override
  void _updateSharedPathData({
    Map<String, Object?> queryParams = const {},
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

  /// Pops the top route of this router's navigator, unless a [PopScope] or
  /// a nested router takes the pop, and otherwise defers to the parent router.
  ///
  /// Works through [Navigator.maybePop], so [PopScope]s are respected. When
  /// the top page holds an [AutoRouter] with more than one page, that nested
  /// router pops its own top page instead, and the page holding it stays.
  /// This is the same order system back uses.
  ///
  /// When this router's navigator has nothing to pop, or no navigator is
  /// mounted because the router has no pages, the call goes to the parent
  /// router. [result] is passed to the popped route.
  ///
  /// Completes with `true` when a route was popped or a [PopScope] handled
  /// the pop, and `false` when no router up to the root could pop.
  @override
  @optionalTypeArgs
  Future<bool> maybePop<T extends Object?>([T? result]) async {
    if (_landingPushes.isNotEmpty) {
      await Future.wait(_landingPushes);
    }
    if (_didPopUnbuiltTop(result)) return true;
    final navigator = _navigatorKey.currentState;
    if (await navigator?.maybePop<T>(result) ?? false) {
      return true;
    } else if (_parent != null) {
      return await _parent!.maybePop(result);
    }
    return false;
  }

  /// Pop current route regardless if it's the last
  /// route in stack or the result of it's PopScopes
  /// see [Navigator.pop]
  ///
  /// Right after [push] or [replace] of a route without guards, the pop
  /// waits for that page to be added and pops it, before it is ever shown.
  /// A push still waiting on a guard is not waited for: the guard may be
  /// waiting on the very route this pop closes, such as a dialog.
  @override
  @optionalTypeArgs
  void pop<T extends Object?>([T? result]) {
    if (_landingPushes.isNotEmpty) {
      unawaited(Future.wait(_landingPushes).then((_) => pop<T>(result)));
      return;
    }
    if (_didPopUnbuiltTop(result)) return;
    final navigator = _navigatorKey.currentState;
    if (navigator != null) {
      navigator.pop(result);
    }
  }

  // Removes the top page when the navigator has not built it yet, as right
  // after a push, and completes it with [result]. Navigator.pop would pop
  // the page below it instead. The last page is never removed this way: right
  // after replaceAll or navigate it is the only page, and the pop goes to what
  // the navigator has built, as a back on a single-page router does.
  bool _didPopUnbuiltTop(Object? result) {
    final navigator = _navigatorKey.currentState;
    final top = _pages.lastOrNull;
    if (navigator == null ||
        top == null ||
        _pages.length < 2 ||
        navigator.widget.pages.contains(top)) {
      return false;
    }
    top.routeData.onPopInvoked(result);
    _removeRoute(top.routeData._route);
    return true;
  }

  /// Removes the very last entry from [_pages]
  bool removeLast() {
    _markRemovedByApp(_pages.reversed.take(1));
    return _removeLast();
  }

  /// Removes given [route] and any corresponding controllers
  ///
  /// finally calls [notifyAll] if notify is true
  void removeRoute(RouteData<dynamic> route, {bool notify = true}) {
    _markRemovedByApp(_pages.where((page) => page.routeData == route));
    _removeRoute(route._route, notify: notify);
  }

  // The app takes [pages] off the stack by its own call, so each leaves as
  // removed and keeps its route from a new page of the same route.
  void _markRemovedByApp(Iterable<AutoRoutePage<Object?>> pages) {
    for (final page in pages) {
      page.markRemoved();
    }
    _markLeaving(pages, .removed);
  }

  /// Called when Page route is popped
  /// this is not called when pageless routes are popped e.g popping a dialog
  /// that does not use [PageRoute] will not trigger this method
  void onPopPage(AutoRoutePage<Object?> page) {
    if (!_pages.contains(page)) return;
    _markLeaving([page], .popped);
    _pages.remove(page);
    _shareTopPathData();
    notifyListeners();
    navigationHistory.rebuildUrlAfterPop();
  }

  void _removeRoute(RouteMatch<Object?> route, {bool notify = true}) {
    final pageIndex = _pages.lastIndexWhere(
      (p) => p.routeData.matchId == route.id,
    );
    if (pageIndex != -1) {
      final page = _pages.removeAt(pageIndex);
      // Removed pages may be disposed without a pop callback from Navigator.
      page.routeData.onPopInvoked(null);
    }
    _shareTopPathData();
    if (notify) {
      notifyAll(forceUrlRebuild: true);
    }
  }

  // Shares the query params and fragment the page now on top was opened with,
  // after the page above it was removed.
  void _shareTopPathData() {
    final top = _pages.lastOrNull?.routeData;
    _updateSharedPathData(
      queryParams: top?._ownQueryParams.rawMap ?? const {},
      fragment: top?._ownFragment ?? '',
      includeAncestors: true,
    );
  }

  void _onNavigate(List<RouteMatch<Object?>> routes) {
    _onNavigateCallback?.call(routes);
  }

  bool _removeLast({bool notify = true}) {
    var didRemove = false;
    if (_pages.isNotEmpty) {
      // Not removeRoute, which counts the page as removed: callers that push
      // in its place count it as replaced.
      _removeRoute(_pages.last.routeData._route, notify: notify);
      didRemove = true;
    }
    return didRemove;
  }

  @override
  List<AutoRoutePage<dynamic>> get stack => .unmodifiable(_pages);

  /// Adds the corresponding page to given [route] to the [_pages] stack
  ///
  /// if [onFailure] callback is provided, navigation errors will be passed to
  /// it otherwise they'll be thrown
  @optionalTypeArgs
  Future<T?> push<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) async {
    return await _findStackScope(route)._push(route, onFailure: onFailure);
  }

  StackRouter _findStackScope(PageRouteInfo route) {
    final stackRouters = _topMostRouter(ignorePagelessRoutes: true)
        ._buildRoutersHierarchy()
        .whereType<StackRouter>();
    return stackRouters.firstWhere(
      (c) => c._canHandleNavigation(route),
      orElse: () => this,
    );
  }

  /// Inserts the corresponding page to given [route] to the [_pages] stack
  ///
  /// if [onFailure] callback is provided, navigation errors will be passed to
  /// it otherwise they'll be thrown
  Future<void> insert(
    PageRouteInfo route, {
    int index = 0,
    OnNavigationFailure? onFailure,
  }) {
    return _findStackScope(route)
        ._push(route, onFailure: onFailure, insertAt: index);
  }

  Future<T?> _popUntilOrPushAll<T extends Object?>(
    List<RouteMatch<Object?>> matches, {
    required Completer<void> pushed,
    required ValueChanged<RouteMatch<Object?>> onLastRouteAdded,
    OnNavigationFailure? onFailure,
    bool isReevaluating = false,
  }) async {
    final kept = isReevaluating ? 0 : _keepPagesUnderTarget(matches);
    final toPush = kept == 0 ? matches : matches.sublist(kept);
    final anchor = toPush.first;
    final anchorPage = _pages.lastWhereOrNull((p) => p.routeKey == anchor.key);
    if (anchorPage != null) {
      for (final candidate in List<AutoRoutePage<Object?>>.unmodifiable(
        _pages,
      ).reversed) {
        _markLeaving([candidate], .removed);
        _pages.removeLast();
        // The anchor page is the first one from the top with its key.
        if (candidate.routeKey == anchorPage.routeKey) break;
      }
      // use the existing match id to avoid breaking child controllers
      toPush[0] = anchor.withId(anchorPage.routeData.matchId);
      for (final ctr in _childControllers) {
        if (ctr.matchId == anchorPage.routeData.matchId) {
          ctr._isMarkedForDataUpdate = true;
        }
      }
    }
    return await _pushAllGuarded(
      toPush,
      onFailure: onFailure,
      updateAncestorsPathData: false,
      isReevaluating: isReevaluating,
      pushed: pushed,
      onLastRouteAdded: onLastRouteAdded,
    );
  }

  // Keeps the pages that [matches], save the last, would build again as they
  // are, from the page the first one matches up, and returns how many: their
  // widgets are not created and built again, as with go_router
  // (flutter/flutter#147639). A page holding a nested router is built again,
  // which updates its router. The pages above the kept ones are removed,
  // except one the next match opens again, which is left for the caller.
  int _keepPagesUnderTarget(List<RouteMatch<Object?>> matches) {
    final start = _pages.lastIndexWhere((p) => p.routeKey == matches.first.key);
    if (start == -1) return 0;
    var kept = 0;
    while (kept < matches.length - 1 && start + kept < _pages.length) {
      final data = _pages[start + kept].routeData;
      if (data._route != matches[kept] ||
          _innerControllerOfMatch(data.matchId) != null) {
        break;
      }
      kept++;
    }
    if (kept == 0) return 0;
    final next = start + kept;
    if (next < _pages.length && _pages[next].routeKey != matches[kept].key) {
      _markLeaving(_pages.sublist(next), .removed);
      _pages.removeRange(next, _pages.length);
    }
    return kept;
  }

  // Why a router that AutoRouter.declarative builds can't push its own pages,
  // and what to do instead.
  String get _managedByWidgetMessage =>
      'The router of ${routeData.name} is built by AutoRouter.declarative, '
      'so the list its routes callback '
      'returns decides its pages, and push, replace and their kin can not '
      'change them. Add the route to the list '
      'that routes callback returns, from state your app updates, or build '
      'this router with AutoRouter() to '
      'navigate it with push and replace.';

  @optionalTypeArgs
  Future<T?> _push<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
    bool notify = true,
    ValueChanged<RouteMatch<Object?>>? onMatch,
    VoidCallback? onAccepted,
    int? insertAt,
  }) async {
    assert(!managedByWidget, _managedByWidgetMessage);
    final match = _matchOrReportFailure(route, onFailure: onFailure);
    if (match == null) {
      return null;
    }
    onMatch?.call(match);
    final landing = root.guards.isEmpty && match.guards.isEmpty
        ? Completer<void>()
        : null;
    if (landing != null) _landingPushes.add(landing.future);
    final result = await _canNavigate(match, onFailure: onFailure);
    if (landing != null) {
      _landingPushes.remove(landing.future);
      // Its listeners run in a later microtask, after this push adds its page.
      landing.complete();
    }
    if (_isDisposed) return null;
    if (result.continueNavigation) {
      onAccepted?.call();
      _updateSharedPathData(
        queryParams: route.rawQueryParams,
        fragment: route.fragment,
        includeAncestors: true,
      );

      return await _addNewPage(
        result.route,
        notify: notify,
        index: insertAt,
        onFailure: onFailure,
      );
    }
    return null;
  }

  /// Removes last entry in stack and pushes given [route]
  /// if last entry == [route] page will just be updated
  ///
  /// The last entry is removed only once the guards of [route] let it
  /// through; a rejected [route] leaves the stack as it was.
  ///
  /// if [onFailure] callback is provided, navigation errors will be passed to
  /// it otherwise they'll be thrown
  @optionalTypeArgs
  Future<T?> replace<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) {
    final scope = _findStackScope(route);
    final replaced = scope._pages.lastOrNull?.routeData;
    return scope._push(
      route,
      onFailure: onFailure,
      onAccepted: () {
        // a guard may have removed it already, e.g. with redirectUntil(replace:
        // true)
        if (replaced != null &&
            scope._pages.any((page) => page.routeData == replaced)) {
          scope
            .._markLeaving(
              scope._pages.where((page) => page.routeData == replaced),
              .replaced,
            )
            .._removeRoute(replaced._route, notify: false);
        }
        markUrlStateForReplace();
      },
    );
  }

  Future<T?> _redirect<T extends Object?>(
    PageRouteInfo route, {
    required void Function(StackRouter scope, RouteMatch<Object?> match)
    onMatch,
    OnNavigationFailure? onFailure,
    bool replace = false,
  }) {
    final scope = _findStackScope(route);
    if (replace) {
      scope
        .._markLeaving(scope._pages.reversed.take(1), .replaced)
        .._removeLast(notify: false);
      markUrlStateForReplace();
    }
    return scope._push(
      route,
      onFailure: onFailure,
      onMatch: (match) => onMatch(scope, match),
    );
  }

  /// Adds the corresponding pages to given [routes] list to the [_pages] stack
  /// at once
  ///
  /// if [onFailure] callback is provided, navigation errors will be passed to
  /// it otherwise they'll be thrown
  Future<void> pushAll(
    List<PageRouteInfo> routes, {
    OnNavigationFailure? onFailure,
  }) {
    assert(routes.isNotEmpty, 'routes must not be empty.');
    return _findStackScope(routes.first)._pushAll(routes, onFailure: onFailure);
  }

  /// Pop the current route off the navigator and push all given [routes] in its
  /// place.
  ///
  /// Like [popAndPush], the pop is forced: it happens before the push, even
  /// when the current route is the only one in its router.
  ///
  /// if [onFailure] callback is provided, navigation errors will be passed to
  /// it otherwise they'll be thrown
  Future<void> popAndPushAll(
    List<PageRouteInfo> routes, {
    OnNavigationFailure? onFailure,
  }) {
    assert(routes.isNotEmpty, 'routes must not be empty.');
    final scope = _findStackScope(routes.first)..pop();
    return scope._pushAll(routes, onFailure: onFailure);
  }

  /// Remove the whole current pages stack and push all given [routes]
  ///
  /// if [onFailure] callback is provided, navigation errors will be passed to
  /// it otherwise they'll be thrown
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
    final matches = _matchAllOrReportFailure(routes, onFailure: onFailure);
    if (matches != null) {
      await _replaceAllMatches(
        matches,
        updateExistingRoutes: updateExistingRoutes,
      );
    }
  }

  Future<void> _replaceAllMatches(
    List<RouteMatch<Object?>> matches, {
    required bool updateExistingRoutes,
  }) async {
    _markLeaving(_pages, .replaced);
    // A guard can reject the new routes; the whole batch is then rejected and
    // the stack restored.
    final previousPages = List.of(_pages);
    final previousStackKey = _stackKey;
    var wasRejected = false;
    _pages.clear();
    if (!updateExistingRoutes) {
      _stackKey = UniqueKey();
    }
    markUrlStateForReplace();
    await _navigateAll(
      matches,
      onFailure: (failure) {
        if (failure is RejectedByGuardFailure &&
            matches.any((match) => match.id == failure.route.id)) {
          wasRejected = true;
        }
      },
    );
    if (wasRejected) {
      for (final page in _pages.where(
        (added) => !previousPages.contains(added),
      )) {
        page.routeData.onPopInvoked(null);
      }
      _pages
        ..clear()
        ..addAll(previousPages);
      _stackKey = previousStackKey;
      markUrlStateForReplace();
      notifyAll(forceUrlRebuild: true);
    }
  }

  /// Pop the whole stack except for the first entry
  void popUntilRoot() {
    assert(
      _navigatorKey.currentState != null,
      'The navigator of this router is not mounted.',
    );
    _didPopUntilShowingNoneBetween((route) => route.isFirst);
  }

  // Navigator.popUntil pops every route with its exit animation, so each
  // page in between shows while it leaves (flutter/flutter#59990). This
  // removes the routes in between first, while the top route still covers
  // them, then pops the top route with its animation over the route that
  // meets [predicate]. Returns whether a route met it.
  bool _didPopUntilShowingNoneBetween(RoutePredicate predicate) {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return false;
    // The navigator's routes, top first: each page's route under the
    // pageless routes pushed over it, newest first.
    final routes = <Route<Object?>>[
      for (final page in _pages.reversed)
        if (pagelessRoutesObserver.routeOf(page) case final pageRoute?) ...[
          ...pagelessRoutesObserver.pagelessRoutesOver(pageRoute).reversed,
          pageRoute,
        ],
    ];
    final top = routes.firstOrNull;
    if (top == null || top != _topRouteOf(navigator)) {
      // A route the router doesn't know of is on top; pop as Flutter does.
      var wasMet = false;
      navigator.popUntil((route) => wasMet = predicate(route));
      return wasMet;
    }
    final target = routes.indexWhere(predicate);
    if (target == 0) return true;
    for (final route in routes.sublist(
      1,
      target == -1 ? routes.length : target,
    )) {
      final page = route.settings;
      // As a pop would, complete the page's push future first, while its
      // route is still known, then take the page off the stack, or the
      // navigator would build it again.
      if (page is AutoRoutePage) page.onPopInvoked(true, null);
      navigator.removeRoute(route);
      if (page is AutoRoutePage) onPopPage(page);
    }
    // A pop may close the top route's own history first, such as an open
    // drawer, so pop until the route leaves, as Navigator.popUntil does.
    navigator.popUntil((route) => route != top);
    return target != -1;
  }

  // The top route of [navigator] that is not leaving: popUntil hands it to
  // the predicate first and stops as the predicate returns true.
  static Route<Object?>? _topRouteOf(NavigatorState navigator) {
    Route<Object?>? top;
    navigator.popUntil((route) {
      top = route;
      return true;
    });
    return top;
  }

  /// Pop the current route off the navigator and push the given [route] in its
  /// place.
  ///
  /// if [onFailure] callback is provided, navigation errors will be passed to
  /// it otherwise they'll be thrown
  @optionalTypeArgs
  Future<T?> popAndPush<T extends Object?, TO extends Object?>(
    PageRouteInfo route, {
    TO? result,
    OnNavigationFailure? onFailure,
  }) {
    final scope = _findStackScope(route)..pop<TO>(result);
    return scope._push(route, onFailure: onFailure);
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
    var wasPredicateSatisfied = false;
    for (final router in routers.whereType<StackRouter>()) {
      router._removeUntil((route) {
        return wasPredicateSatisfied = predicate(route);
      });
      if (wasPredicateSatisfied) break;
    }
    return wasPredicateSatisfied;
  }

  /// Calls [maybePop] repeatedly on the navigator until the predicate returns
  /// true.
  ///
  /// see [Navigator.popUntil]
  ///
  /// if [scoped] is set to true the predicate will
  /// visit all StackRouters in hierarchy starting from
  /// top until satisfied
  void popUntil(RoutePredicate predicate, {bool scoped = true}) {
    if (scoped) {
      _didPopUntilShowingNoneBetween(predicate);
      return;
    }
    final routers = _topMostRouter()._buildRoutersHierarchy();
    for (final router in routers.whereType<StackRouter>()) {
      final navState = router._navigatorKey.currentState;
      if (navState == null) break;
      if (router._didPopUntilShowingNoneBetween(predicate)) break;
    }
  }

  // Like [popUntil], but the last navigator it walks keeps its first route,
  // so a predicate no route satisfies doesn't pop every page and leave the
  // screen blank. popUntil itself still pops them all, as clearing the stack
  // with `popUntil((_) => false)` relies on.
  void _popUntilKeepingFirstPage(
    RoutePredicate predicate, {
    required bool scoped,
  }) {
    if (scoped) {
      return _navigatorKey.currentState?.popUntil(
        (route) => predicate(route) || route.isFirst,
      );
    }
    final routers = _topMostRouter()
        ._buildRoutersHierarchy()
        .whereType<StackRouter>()
        .toList();
    var wasPredicateSatisfied = false;
    for (final router in routers) {
      final navState = router._navigatorKey.currentState;
      if (navState == null) break;
      final isLast = router == routers.last;
      navState.popUntil(
        (route) =>
            (wasPredicateSatisfied = predicate(route)) ||
            isLast && route.isFirst,
      );
      if (wasPredicateSatisfied) break;
    }
  }

  bool _removeUntil(RouteDataPredicate predicate, {bool notify = true}) {
    var didRemove = false;
    for (final candidate in List<AutoRoutePage<Object?>>.unmodifiable(
      _pages,
    ).reversed) {
      if (predicate(candidate.routeData)) {
        break;
      }
      _markRemovedByApp([candidate]);
      _removeLast(notify: false);
      didRemove = true;
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
    for (final entry in List<AutoRoutePage<Object?>>.unmodifiable(_pages)) {
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
  void updateDeclarativeRoutes(List<PageRouteInfo> routes) {
    _pages.clear();
    for (final route in routes) {
      final match = _matchOrReportFailure(route);
      if (match == null) {
        break;
      }
      if (match.guards.isNotEmpty) {
        throw FlutterError('Declarative routes can not have guards');
      }
      final data = _createRouteData<Object?>(match, routeData);
      _pages.add(data.buildPage());
    }
    // The app's list builds new pages each time, so only pops are reported.
    _pagesAtLastLeaveReport = List.of(_pages);
    _leaveKinds.clear();

    navigationHistory.onNewUrlState(
      UrlState.fromSegments(
        root.currentSegments,
        shouldReplace: current == routeData,
      ),
      notify: false,
    );
  }

  // async, so a match failure reaches the returned future, not the caller's
  // stack. Completes once every guard has decided, not when the last page is
  // popped.
  Future<void> _pushAll(
    List<PageRouteInfo> routes, {
    OnNavigationFailure? onFailure,
    bool notify = true,
  }) async {
    final matches = _matchAllOrReportFailure(routes, onFailure: onFailure);
    if (matches != null) {
      await _pushAllGuarded<void>(
        matches,
        onFailure: onFailure,
        notify: notify,
        returnLastRouteCompleter: false,
      );
    }
  }

  @optionalTypeArgs
  Future<T?> _pushAllGuarded<T extends Object?>(
    List<RouteMatch<Object?>> routes, {
    OnNavigationFailure? onFailure,
    bool notify = true,
    bool updateAncestorsPathData = true,
    bool returnLastRouteCompleter = true,
    bool isReevaluating = false,
    Completer<void>? pushed,
    ValueChanged<RouteMatch<Object?>>? onLastRouteAdded,
  }) async {
    assert(!managedByWidget, _managedByWidgetMessage);

    // A page popped since the stack was collected for reevaluation stays
    // closed, with the pages above it.
    bool wasPopped(RouteMatch<Object?> match) =>
        match is ReevaluatableRouteMatch &&
        match.currentPage.routeData._isPoppedByNavigator;
    final link = root._startingLink;
    for (var i = 0; i < routes.length; i++) {
      if (wasPopped(routes[i])) break;
      final result = await _canNavigate(
        routes[i],
        onFailure: onFailure,
        pendingRoutes: routes
            .whereIndexed((index, element) => index > i)
            .toList(),
        isReevaluating: isReevaluating,
      );
      if (_isDisposed) break;
      // A later link took over while a guard decided.
      if (link != null && root._linkCount != link) break;
      final match = result.route;
      if (wasPopped(match)) break;
      if (result.continueNavigation) {
        if (i != (routes.length - 1)) {
          if (match is ReevaluatableRouteMatch) {
            _addReevaluatedPage(match, notify: false);
          } else {
            unawaited(_addNewPage<T>(match, notify: false));
          }
        } else {
          _updateSharedPathData(
            queryParams: match.queryParams.rawMap,
            fragment: match.fragment,
            includeAncestors: updateAncestorsPathData,
          );
          onLastRouteAdded?.call(match);
          if (match is ReevaluatableRouteMatch) {
            _addReevaluatedPage(match, notify: notify);
          } else {
            final completer = _addNewPage<T>(match, notify: notify);
            if (pushed != null && !pushed.isCompleted) pushed.complete();
            if (returnLastRouteCompleter) {
              return await completer;
            }
          }
        }

        if (isReevaluating && !result.reevaluateNext) {
          break;
        }
      } else {
        // A page its guard now closes leaves its history entry to the page
        // below, as a pop does; a new entry would lead back to the guard.
        if (match is ReevaluatableRouteMatch) {
          _markLeaving([match.currentPage], .removed);
        }
        if (match is ReevaluatableRouteMatch<Object?, Object?> &&
            _pages.remove(match.currentPage)) {
          markUrlStateForReplace();
        }
        break;
      }
    }
    return null;
  }

  void _addReevaluatedPage(
    ReevaluatableRouteMatch<Object?, Object?> match, {
    bool notify = true,
  }) {
    var page = match.currentPage;
    final data = page.routeData;
    // args a guard set are shown by a page built with them, which keeps the
    // route and its state
    if (match.args != data.args) {
      data._updateRoute(match.originalMatch);
      page = page.rebuild();
    }
    // the page may have been kept in the stack while a guard was redirecting
    final index = _pages.indexOf(match.currentPage);
    if (index == -1) {
      _pages.add(page);
    } else {
      _pages[index] = page;
    }
    if (notify) {
      notifyAll();
    }
  }

  Future<T?> _addNewPage<T extends Object?>(
    RouteMatch<Object?> route, {
    bool notify = true,
    int? index,
    OnNavigationFailure? onFailure,
  }) {
    final shownTop = _pages.lastOrNull?.routeData;
    if (shownTop != null && !shownTop._route.keepHistory) {
      markUrlStateForReplace();
      _removeRoute(shownTop._route, notify: false);
    }
    var match = route;
    final takenOver = index == null ? _shownTopTakenOverBy(route) : null;
    if (takenOver != null) {
      // The page takes over the route and the nested router of [takenOver], so
      // it keeps its match id, as navigate does, for the router to stay its
      // own.
      match = route.withId(takenOver.matchId);
      for (final ctr in _childControllers) {
        if (ctr.matchId == takenOver.matchId) {
          ctr._isMarkedForDataUpdate = true;
        }
      }
    }
    final data = _createRouteData<T>(
      match,
      routeData,
      popCompleter: Completer<T?>(),
    );
    final page = data.buildPage<T>();
    if (index != null) {
      _pages.insert(index, page);
    } else {
      _pages.add(page);
    }
    if (notify) {
      notifyAll();
    }
    // After the notification, so the url this page makes keeps its own replace
    // mark and the nested router's url gets one of its own.
    if (takenOver != null) {
      _openChildrenInTakenOverRouter(data, onFailure: onFailure);
    }
    return data.popped;
  }

  // The data of the page the navigator shows on top, once that page has left
  // the stack and [route] is about to go on top in its place. The new page
  // then takes over its route, see [AutoRoutePage.canUpdate], with the nested
  // router built inside it. A [route] that already has the page's match id,
  // as navigate gives it, comes with a caller that updates that router. A page
  // the app removed itself keeps its route (#1204).
  RouteData<Object?>? _shownTopTakenOverBy(RouteMatch<Object?> route) {
    final shownRoute = pagelessRoutesObserver.topPageRoute;
    final shownPage = shownRoute?.settings;
    if (shownRoute == null ||
        !shownRoute.isActive ||
        shownPage is! AutoRoutePage<Object?> ||
        shownPage.isRemoved ||
        _pages.contains(shownPage)) {
      return null;
    }
    final data = shownPage.routeData;
    final doesTakeOver =
        data.key == route.key &&
        data.stackKey == _stackKey &&
        data.matchId != route.id;
    return doesTakeOver ? data : null;
  }

  // A fresh nested router opens the children of its page's route; the one a
  // page took over already shows the children of the page before, so it is
  // sent to the new ones, as if built anew. A route given no children comes
  // with its initial child, as with navigate; with no initial child either,
  // the router keeps the children it shows.
  void _openChildrenInTakenOverRouter(
    RouteData<Object?> data, {
    OnNavigationFailure? onFailure,
  }) {
    final inner = _innerControllerOfMatch(data.matchId);
    if (inner == null || !data.hasPendingChildren) return;
    final children = List<RouteMatch<Object?>>.unmodifiable(
      data.pendingChildren,
    );
    data.pendingChildren.clear();
    if (inner is StackRouter && !inner.managedByWidget) {
      unawaited(inner._replaceAllMatches(children, updateExistingRoutes: true));
    } else {
      unawaited(inner._navigateAll(children, onFailure: onFailure));
    }
  }

  Future<ResolverResult> _canNavigate(
    RouteMatch<Object?> route, {
    OnNavigationFailure? onFailure,
    List<RouteMatch<Object?>> pendingRoutes = const [],
    bool isReevaluating = false,
  }) async {
    var routeToCheck = route;
    final guards = <AutoRouteGuard>[...root.guards, ...routeToCheck.guards];
    if (guards.isEmpty) {
      return await SynchronousFuture(
        ResolverResult(
          continueNavigation: true,
          reevaluateNext: true,
          route: routeToCheck,
        ),
      );
    }
    var shouldReevaluateNext = true;
    for (final guard in guards) {
      if (routeToCheck.evaluatedGuards.contains(guard)) {
        routeToCheck = routeToCheck.copyWith(
          evaluatedGuards: List.from(
            routeToCheck.evaluatedGuards.where((e) => e != guard),
          ),
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
      final result = await resolver.checkGuard(guard, this);
      routeToCheck = result.route;
      if (!result.reevaluateNext) {
        shouldReevaluateNext = false;
      }
      if (!result.continueNavigation) {
        if (onFailure != null) {
          onFailure(RejectedByGuardFailure(routeToCheck, guard));
        }
        activeGuardObserver._remove(guardEntry);
        return result;
      }
      activeGuardObserver._remove(guardEntry);
    }
    return ResolverResult(
      continueNavigation: true,
      reevaluateNext: shouldReevaluateNext,
      route: routeToCheck,
    );
  }

  /// Preforms pop-until finds cosponsoring route with [routes].first
  /// then pushes all [routes]
  ///
  /// if [onFailure] callback is provided, navigation errors will be passed to
  /// it otherwise they'll be thrown
  Future<void> navigateAll(
    List<RouteMatch<dynamic>> routes, {
    OnNavigationFailure? onFailure,
  }) {
    return _navigateAll(routes, onFailure: onFailure);
  }

  @override
  Future<T?> _navigateAll<T extends Object?>(
    List<RouteMatch<Object?>> routes, {
    OnNavigationFailure? onFailure,
    bool isReevaluating = false,
  }) async {
    // A reevaluation takes every page off and puts back the ones its guards
    // keep, so only the pages it closes are reported, once it ends.
    if (isReevaluating && _leaveReportHolds == 0) {
      return await _holdingLeaveReports(
        () =>
            _navigateAll<T>(routes, onFailure: onFailure, isReevaluating: true),
      );
    }
    // pages pushed after the stack was composed for reevaluation are not in
    // [routes]. A reevaluated page may be rebuilt, so it's known by its route
    // data
    final reevaluatedRoutes = {
      for (final route in routes)
        if (route is ReevaluatableRouteMatch) route.currentPage.routeData,
    };
    bool wasReevaluated(AutoRoutePage<Object?> page) =>
        reevaluatedRoutes.contains(page.routeData);
    final pushedMeanwhile = <AutoRoutePage<Object?>>[];
    if (isReevaluating) {
      pushedMeanwhile.addAll(_pages.whereNot(wasReevaluated));
      _pages.clear();
    }
    Future<T?>? popped;
    if (routes.isNotEmpty) {
      var mayUpdateRoute = routes.last;
      if (!managedByWidget) {
        // The future of a pushed page completes when the page is popped, so
        // wait only until the page is added, to keep updating nested routers
        // right away.
        final pushed = Completer<void>();
        popped = _popUntilOrPushAll<T>(
          routes,
          onFailure: onFailure,
          isReevaluating: isReevaluating,
          pushed: pushed,
          // a guard may have overridden the route, e.g. its children
          onLastRouteAdded: (match) => mayUpdateRoute = match,
        );
        await Future.any([pushed.future, popped]);
        if (isReevaluating) {
          // put pages pushed before or during the reevaluation back on top of
          // the reevaluated ones
          final pushedDuring = _pages.whereNot(wasReevaluated).toList();
          _pages
            ..removeWhere((page) => !wasReevaluated(page))
            ..addAll([...pushedMeanwhile, ...pushedDuring]);
        } else if (pushed.isCompleted) {
          _closePagelessRoutesOverTop();
        }
      } else {
        _onNavigate(routes);
      }
      final mayUpdateController = _topInnerControllerOf(mayUpdateRoute.key);
      if (mayUpdateController != null) {
        final newChildren = mayUpdateRoute.children ?? const [];
        // Only a declarative stack router is managed by its widget.
        if (mayUpdateController is StackRouter &&
            mayUpdateController.managedByWidget) {
          mayUpdateController._onNavigate(newChildren);
        }
        // children a guard set while reevaluating are new routes, not pages
        // being reevaluated
        final areChildrenOverridden = newChildren.any(
          (child) => child is! ReevaluatableRouteMatch,
        );
        return await mayUpdateController._navigateAll(
          newChildren,
          onFailure: onFailure,
          isReevaluating: isReevaluating && !areChildrenOverridden,
        );
      }
    } else if (!managedByWidget) {
      _reset();
    }
    return await popped;
  }

  void _reset() {
    _markLeaving(_pages, .removed);
    _pages.clear();
    _childControllers.clear();
  }

  // After navigate or replaceAll lands on a page the navigator already shows,
  // that page is updated in place, so the routes pushed over it with
  // Navigator.push, such as dialogs, would stay on screen. They close: those
  // on top are popped, those under pages leaving now are removed unseen.
  // A guard reevaluation keeps them, since a guard may be showing one.
  void _closePagelessRoutesOverTop() {
    final top = _pages.lastOrNull;
    if (top == null) return;
    final shownRoute = pagelessRoutesObserver.routeWhere(
      (route) =>
          route.settings is AutoRoutePage &&
          top.canUpdate(route.settings as Page<Object?>),
    );
    if (shownRoute == null) return;
    final pageless = pagelessRoutesObserver.pagelessRoutesOver(shownRoute);
    final navigator = shownRoute.navigator;
    if (pageless.isEmpty || navigator == null) return;
    if (pageless.contains(pagelessRoutesObserver.current)) {
      navigator.popUntil((route) => route == shownRoute);
    } else {
      pageless.forEach(navigator.removeRoute);
    }
  }

  /// Pushes the given [route] and removes the routes below it until the
  /// [predicate] returns true, as [Navigator.pushAndRemoveUntil] does.
  ///
  /// The [predicate] is asked about the routes from the top down, dialogs
  /// and other pageless routes included. The routes it rejects are removed,
  /// not popped, so they never show while [route] slides in: navigator
  /// observers hear [NavigatorObserver.didRemove] for them, their PopScope
  /// is not asked, and their push futures complete with null. They are
  /// removed only once the guards of [route] let it through; a rejected
  /// [route] leaves the stack as it was.
  ///
  /// if [scopedPopUntil] is false the [predicate] visits all StackRouters
  /// in hierarchy starting from the top-most one until satisfied. The routes
  /// it rejects in a nested router are removed the same way, and a nested
  /// router whose own page is removed keeps its pages on screen under
  /// [route] until it goes.
  ///
  /// if [onFailure] callback is provided, navigation errors will be passed to
  /// it otherwise they'll be thrown
  @optionalTypeArgs
  Future<T?> pushAndPopUntil<T extends Object?>(
    PageRouteInfo route, {
    required RoutePredicate predicate,
    bool scopedPopUntil = true,
    OnNavigationFailure? onFailure,
  }) {
    final scope = _findStackScope(route);
    return scope._push(
      route,
      onFailure: onFailure,
      onAccepted: () {
        if (scopedPopUntil) {
          scope._removePagesUntil(
            scope._rejectedPagesUntil(predicate).rejected,
            isForPush: true,
          );
          return;
        }
        // The predicate is asked about every router first, so a nested
        // router whose own page goes too is left as it is: its top page stays
        // under [route] while it slides in, as the scope's old top does.
        final routers = _topMostRouter()
            ._buildRoutersHierarchy()
            .whereType<StackRouter>()
            .toList();
        final rejectedPages = <int>[];
        for (final router in routers) {
          final (:isAccepted, :rejected) = router._rejectedPagesUntil(
            predicate,
          );
          rejectedPages.add(rejected);
          if (isAccepted) break;
        }
        // Each router sits on the top page of the next one.
        var isStillShown = true;
        for (var i = rejectedPages.length - 1; i >= 0; i--) {
          if (isStillShown) {
            routers[i]._removePagesUntil(
              rejectedPages[i],
              isForPush: routers[i] == scope,
            );
          }
          isStillShown = isStillShown && rejectedPages[i] == 0;
        }
      },
    );
  }

  // Asks [predicate] about the routes from the top down until it accepts one.
  // Pageless routes it rejects, such as dialogs, are removed on the way; the
  // pages it rejects are only counted, for [_removePagesUntil].
  ({bool isAccepted, int rejected}) _rejectedPagesUntil(
    RoutePredicate predicate,
  ) {
    // Pageless routes, such as dialogs, sit above the top page.
    while (hasPagelessTopRoute) {
      final top = pagelessRoutesObserver.current!;
      if (predicate(top)) return (isAccepted: true, rejected: 0);
      final navigator = top.navigator;
      navigator?.removeRoute(top);
      if (pagelessRoutesObserver.current == top) break;
    }
    var rejected = 0;
    for (final page in _pages.reversed) {
      final shownRoute = pagelessRoutesObserver.routeOf(page);
      final bool isAccepted;
      if (shownRoute != null) {
        isAccepted = predicate(shownRoute);
      } else {
        // a page pushed in this frame has no route yet
        final unshownRoute = _UnshownPageRoute(page);
        isAccepted = predicate(unshownRoute);
        unshownRoute.release();
      }
      if (isAccepted) return (isAccepted: true, rejected: rejected);
      rejected++;
    }
    return (isAccepted: false, rejected: rejected);
  }

  // Removes the [count] top pages without animating them out. With [isForPush]
  // a page pushed in the same update makes the navigator remove them and keep
  // the old top under the new page; otherwise each is removed from the
  // navigator here, and this router is notified.
  void _removePagesUntil(int count, {required bool isForPush}) {
    _markLeaving(_pages.reversed.take(count), isForPush ? .replaced : .removed);
    for (var i = 0; i < count; i++) {
      final shownRoute = pagelessRoutesObserver.routeOf(_pages.last);
      if (!isForPush && shownRoute != null) {
        final shownNavigator = shownRoute.navigator;
        shownNavigator?.removeRoute(shownRoute);
      }
      _removeLast(notify: false);
      if (shownRoute != null) {
        // drops the removed page's history entry, as a pop does
        navigationHistory.rebuildUrlAfterPop();
      } else {
        // the browser never showed its url; the next page takes its entry
        markUrlStateForReplace();
      }
    }
    if (!isForPush && count > 0) {
      notifyAll(forceUrlRebuild: true);
    }
  }

  /// Removes last entry in stack and pushes given [path]
  /// if last entry.path == [path] page will just be updated
  ///
  /// if [includePrefixMatches] is true prefixed-matches
  /// will be added to to target destination
  /// see [RouteMatcher.matchUri]
  ///
  /// if [onFailure] callback is provided, navigation errors will be passed to
  /// it otherwise they'll be thrown
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
      scope.router
        .._markLeaving(scope.router._pages.reversed.take(1), .replaced)
        .._removeLast(notify: false);
      markUrlStateForReplace();
      return scope.router._pushAllGuarded(scope.matches, onFailure: onFailure);
    }
    return SynchronousFuture(null);
  }

  /// Adds corresponding page to given [path] to [_pages] stack
  ///
  /// if [includePrefixMatches] is true prefixed-matches
  /// will be added to to target destination
  /// see [RouteMatcher.matchUri]
  ///
  /// if [onFailure] callback is provided, navigation errors will be passed to
  /// it otherwise they'll be thrown
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
      return scope.router._pushAllGuarded(scope.matches, onFailure: onFailure);
    }
    return SynchronousFuture(null);
  }

  /// Helper to pop all routes until route with [name] is found
  /// see [popUntil]
  ///
  /// When no route has [name], it pops down to the first page and keeps it,
  /// instead of leaving no page.
  void popUntilRouteWithName(String name, {bool scoped = true}) {
    _popUntilKeepingFirstPage(ModalRoute.withName(name), scoped: scoped);
  }

  /// Helper to pop all routes until route with [path] is found
  /// see [popUntil]
  ///
  /// When no route has [path], it pops down to the first page and keeps it,
  /// instead of leaving no page.
  void popUntilRouteWithPath(String path, {bool scoped = true}) {
    _popUntilKeepingFirstPage((route) {
      if (route.settings is AutoRoutePage) {
        return (route.settings as AutoRoutePage).routeData.match == path;
      }
      // Assuming pageless routes are either dialogs or bottomSheetModals and
      // the user set a path as in RouteSettings(name: path) when showing theme
      return route.settings.name == path;
    }, scoped: scoped);
  }
}

/// An Implementation of StackRouter used by nested
/// [AutoRouter] widgets
class NestedStackRouter extends StackRouter {
  /// Default constructor
  new({
    required RouteCollection routeCollection,
    required super.key,
    required super.matchId,
    required RouteData<dynamic> routeData,
    required RoutingController super.parent,
    this.managedByWidget = false,
    super.onNavigate,
    super.navigatorKey,
  }) : _routeCollection = routeCollection,
       _matcher = RouteMatcher(routeCollection),
       _routeData = routeData {
    // When a widget above AutoRouter builds it anew, such as in another place
    // of its page when a two-pane layout becomes one pane, the new router is
    // created before the outgoing one of the same page is disposed, so it
    // opens the pages the outgoing router has open.
    final outgoing = _parent?._innerControllerOfMatch(matchId);
    if (!managedByWidget &&
        !routeData.hasPendingChildren &&
        outgoing is NestedStackRouter &&
        !outgoing.managedByWidget) {
      routeData.pendingChildren.addAll(outgoing._openMatches());
    }
  }
  RouteCollection _routeCollection;
  RouteMatcher _matcher;

  @override
  RouteCollection get routeCollection => _routeCollection;

  @override
  RouteMatcher get matcher => _matcher;

  @override
  void _reassemble() {
    if (_parent?._reassembledSubCollection(_routeData.name)
        case final collection?) {
      _routeCollection = collection;
      _matcher = RouteMatcher(collection);
    }
    super._reassemble();
  }

  @override
  final bool managedByWidget;

  RouteData<Object?> _routeData;

  @override
  RouteData<dynamic> get routeData => _routeData;

  @override
  void updateRouteData(RouteData<dynamic> data) {
    _routeData = data;
    for (final page in _pages) {
      page.routeData._parent = data;
    }
  }

  /// Adds the initial routes to the stack right away, so the first page of
  /// this router is part of the frame that builds it.
  ///
  /// This lets a [Hero] on the page that opened this router's page fly to a
  /// [Hero] on its first page: Flutter starts the flight right after the frame
  /// of the push, and looks for the destination [Hero] in what is built then.
  ///
  /// Returns false and adds nothing when the routes have to wait for
  /// [setupInitialRoutes], which runs guards with a context.
  @internal
  bool setupInitialRoutesSynchronously() {
    if (managedByWidget || root.guards.isNotEmpty) {
      return false;
    }
    final hasPendingChildren = _routeData.hasPendingChildren;
    final initialRoutes = hasPendingChildren
        ? List<RouteMatch<Object?>>.unmodifiable(_routeData.pendingChildren)
        : matcher.match('');
    final top = initialRoutes?.lastOrNull;
    if (initialRoutes == null ||
        top == null ||
        initialRoutes.any((route) => route.guards.isNotEmpty)) {
      return false;
    }
    for (final route in initialRoutes) {
      unawaited(_addNewPage(route, notify: false));
    }
    _updateSharedPathData(
      queryParams: top.queryParams.rawMap,
      fragment: top.fragment,
      includeAncestors: true,
    );
    if (hasPendingChildren) {
      _routeData.pendingChildren.clear();
    }
    return true;
  }

  @internal
  /// pushes the initial routes to the stack
  void setupInitialRoutes() {
    if (_routeData.hasPendingChildren) {
      final initialRoutes = List<RouteMatch<Object?>>.unmodifiable(
        _routeData.pendingChildren,
      );
      if (managedByWidget) {
        pendingRoutesHandler._initialPendingRoutes = initialRoutes
            .map((e) => e.toPageRouteInfo())
            .toList();
      } else {
        unawaited(
          _pushAllGuarded(initialRoutes, returnLastRouteCompleter: false),
        );
      }
      _routeData.pendingChildren.clear();
    } else {
      final possibleInitialRoutes = matcher.match('');
      if (possibleInitialRoutes != null) {
        unawaited(
          _pushAllGuarded(
            possibleInitialRoutes,
            returnLastRouteCompleter: false,
          ),
        );
      }
    }
  }
}

// How a change of the active tab ended: the tab is active, its guards kept
// it out, or a later change replaced it while its guards decided.
enum _TabChange { done, rejected, replaced }

class _RouterScopeResult<T extends RoutingController> {
  const new(this.router, this.matches);
  final T router;
  final List<RouteMatch<Object?>> matches;
}

/// Holds a one-time read initial routes value
/// used by declarative routing widgets
class PendingRoutesHandler {
  List<PageRouteInfo<Object?>>? _initialPendingRoutes;

  /// Whether [_initialPendingRoutes] is not empty
  bool get hasPendingRoutes => _initialPendingRoutes?.isNotEmpty == true;

  /// Reads [_initialPendingRoutes] without deleting it's value
  List<PageRouteInfo<dynamic>>? get peek => _initialPendingRoutes;

  /// One time read pending routes
  ///
  /// [_initialPendingRoutes] is deleted after the read
  List<PageRouteInfo<dynamic>>? get initialPendingRoutes {
    if (_initialPendingRoutes == null) return null;
    final routes = List.of(_initialPendingRoutes!);
    _initialPendingRoutes = null;
    return routes;
  }
}

/// Observers the current guards processing navigation event
class ActiveGuardObserver extends ValueNotifier<List<GuardEntry>> {
  /// Default controller
  new() : super([]);

  // A guard can finish after its router, and this observer, are disposed.
  bool _isDisposed = false;

  /// Adds `guard` to the list of active guards
  void _add(GuardEntry entry) {
    if (_isDisposed) return;
    value = [...value, entry];
  }

  /// Removes `guard` from the list of active guards
  void _remove(GuardEntry entry) {
    if (_isDisposed) return;
    value = [...value..remove(entry)];
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// Whether there's a guard  pending completion
  bool get guardInProgress => value.isNotEmpty;

  /// returns a list of active guards
  List<AutoRouteGuard> get activeGuards =>
      .unmodifiable(value.map((e) => e.guard));
}

/// A class that holds a guard and it's corresponding resolver
class GuardEntry {
  /// Default constructor
  const new(this.guard, this._resolver);

  /// The auto route guard
  final AutoRouteGuard guard;

  final NavigationResolver _resolver;
}

// Stands in for the route of a page the navigator has not built yet, so a
// [RoutePredicate] can still be asked about the page.
class _UnshownPageRoute extends Route<Object?> {
  new(Page<Object?> page) : super(settings: page);

  void release() => dispose();
}
