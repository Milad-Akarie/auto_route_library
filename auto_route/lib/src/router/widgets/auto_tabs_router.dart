import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/router/widgets/auto_tab_view.dart';
import 'package:auto_route/src/utils/collection.dart';
import 'package:collection/collection.dart' hide ListExtensions;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

part 'auto_tabs_router_builder.dart';
part 'auto_tabs_router_indexed_stack.dart';
part 'auto_tabs_router_page_view.dart';
part 'auto_tabs_router_tab_bar.dart';
part 'indexed_stack_builder.dart';
part 'keep_alive_tab.dart';

/// Signature for a wrapper builder used by [_AutoTabsRouterIndexedStack]
typedef AnimatedIndexedStackBuilder = Widget Function(
  BuildContext context,
  Widget child,
);

/// Signature for a translation builder used by [_AutoTabsRouterIndexedStack]
typedef AnimatedIndexedStackTransitionBuilder = Widget Function(
  BuildContext context,
  Widget child,
  Animation<double> animation,
);

/// Signature for a wrapper builder used by [_AutoTabsRouterBuilder]
typedef AutoTabsBuilder = Widget Function(
  BuildContext context,
  List<Widget> children,
  TabsRouter tabsRouter,
);

/// Signature for a wrapper builder used by [_AutoTabsRouterPageView]
typedef AutoTabsPageViewBuilder = Widget Function(
  BuildContext context,
  Widget child,
  PageController pageController,
);

/// Signature for a wrapper builder used by [_AutoTabsRouterTabBar]
typedef AutoTabsTabBarBuilder = Widget Function(
  BuildContext context,
  Widget child,
  TabController tabController,
);

/// Signature for a callback function used by [_AutoTabsRouterBuilder]
typedef OnNavigationChanged = void Function(TabsRouter tabsRouter);

/// An implementation of a router widget that handles parallel routeing
abstract class AutoTabsRouter extends StatefulWidget {
  /// Builds an [AutoTabsRouter] to uses
  /// a [IndexedStack] to render pages
  const factory({
    Key? key,
    List<PageRouteInfo>? routes,
    bool lazyLoad,
    Duration duration,
    Curve curve,
    AnimatedIndexedStackBuilder? builder,
    AnimatedIndexedStackTransitionBuilder transitionBuilder,
    int homeIndex,
    bool backThroughHistory,
    bool inheritNavigatorObservers,
    NavigatorObserversBuilder navigatorObservers,
  }) = _AutoTabsRouterIndexedStack;

  const new _({
    required this.routes,
    super.key,
    this.homeIndex = -1,
    this.backThroughHistory = false,
    this.inheritNavigatorObservers = true,
    this.navigatorObservers =
        AutoRouterDelegate.defaultNavigatorObserversBuilder,
  });

  /// Builds an [AutoTabsRouter] to uses
  /// a [PageView] to render pages
  ///
  /// With [lazyLoad] true, the default, each tab's page is built once the
  /// tab is first shown; with false, every tab's page is built with the
  /// tabs. See [AutoPageView.lazyLoad].
  const factory pageView({
    Key? key,
    List<PageRouteInfo>? routes,
    AutoTabsPageViewBuilder? builder,
    bool lazyLoad,
    int homeIndex,
    bool backThroughHistory,
    bool animatePageTransition,
    Axis scrollDirection,
    Duration duration,
    Curve curve,
    bool inheritNavigatorObservers,
    NavigatorObserversBuilder navigatorObservers,
    ScrollPhysics? physics,
    DragStartBehavior dragStartBehavior,
  }) = _AutoTabsRouterPageView;

  /// Builds an [AutoTabsRouter] to uses
  /// a `TabView` to render pages
  ///
  /// With [lazyLoad] true, the default, each tab's page is built once the
  /// tab is first shown; with false, every tab's page is built with the
  /// tabs, as AutoTabView does with its own `lazyLoad`.
  const factory tabBar({
    Key? key,
    List<PageRouteInfo>? routes,
    AutoTabsTabBarBuilder? builder,
    bool lazyLoad,
    int homeIndex,
    bool backThroughHistory,
    Duration? duration,
    Axis scrollDirection,
    Curve curve,
    bool inheritNavigatorObservers,
    NavigatorObserversBuilder navigatorObservers,
    ScrollPhysics? physics,
    DragStartBehavior dragStartBehavior,
  }) = _AutoTabsRouterTabBar;

  /// Builds an [AutoTabsRouter] with a custom builder
  ///
  /// Clients can use this builder to render tabbed-pages
  const factory builder({
    required AutoTabsBuilder builder,
    Key? key,
    List<PageRouteInfo>? routes,
    OnNavigationChanged? onNavigate,
    OnNavigationChanged? onRouterReady,
    int homeIndex,
    bool backThroughHistory,
    bool inheritNavigatorObservers,
    NavigatorObserversBuilder navigatorObservers,
  }) = _AutoTabsRouterBuilder;

  /// The list of pages this router will handle
  final List<PageRouteInfo>? routes;

  /// A builder function that returns a list of observes
  ///
  /// Why isn't this a list of navigatorObservers?
  /// The reason for that is a [NavigatorObserver] instance can only
  /// be used by a single [Navigator], so unless you're using a one
  /// single router or you don't want your nested routers to inherit
  /// observers make sure navigatorObservers builder always returns
  /// fresh observer instances.
  final NavigatorObserversBuilder navigatorObservers;

  /// Whether this router should inherit it's ancestor's observers
  final bool inheritNavigatorObservers;

  /// The index to pop from
  ///
  /// if activeIndex != homeIndex
  /// set activeIndex to homeIndex
  /// else pop parent
  final int homeIndex;

  /// Whether back shows the tabs the user visited before the active one, the
  /// latest first, before it leaves the tabs. Defaults to false: back goes
  /// to the [homeIndex] tab, or out of the tabs when there is none.
  ///
  /// After tabs 0, 2 and 1, back shows 2, then 0, then leaves. A tab visited
  /// again is gone back to once, from where it was left last. With a
  /// [homeIndex], back shows the home tab once the history is gone through.
  /// See [TabsRouter.backThroughHistory].
  final bool backThroughHistory;

  /// Looks up and returns the scoped `controller`
  ///
  /// if watch is true dependent widget will watch changes
  /// of this scope otherwise it would just read it
  ///
  /// throws an error if it does not find it
  static TabsRouter of(BuildContext context, {bool watch = false}) {
    final scope = TabsRouterScope.of(context, watch: watch);
    if (kDebugMode && scope == null) {
      throw FlutterError(
        'AutoTabsRouter operation requested with a context that does not '
        'include an AutoTabsRouter.\n'
        'The context used to retrieve the AutoTabsRouter must be that of a '
        'widget that '
        'is a descendant of an AutoTabsRouter widget.',
      );
    }
    return scope!.controller;
  }
}

/// The state implementation of [AutoTabsRouter]
abstract class AutoTabsRouterState<T extends AutoTabsRouter> extends State<T> {
  TabsRouter? _controller;
  late RoutingController _parentController;

  /// The [TabsRouter] controlling this tab-router widget
  TabsRouter? get controller => _controller;
  late List<NavigatorObserver> _navigatorObservers;
  late NavigatorObserversBuilder _inheritableObserversBuilder;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      final parentRoute = RouteData.of(context);
      final parentScope = RouterScope.of(context, watch: true);
      _inheritableObserversBuilder = () {
        final observers = widget.navigatorObservers();
        if (!widget.inheritNavigatorObservers) {
          return observers;
        }
        final inheritedObservers = parentScope.inheritableObserversBuilder();
        return inheritedObservers + observers;
      };
      _navigatorObservers = _inheritableObserversBuilder();
      _parentController = parentScope.controller;
      _controller = TabsRouter(
        parent: _parentController,
        key: parentRoute.key,
        matchId: parentRoute.matchId,
        homeIndex: widget.homeIndex,
        backThroughHistory: widget.backThroughHistory,
        routeData: parentRoute,
        preload: onPreload,
        routeCollection: _parentController.routeCollection.subCollectionOf(
          parentRoute.name,
        ),
      );
      _parentController.attachChildController(_controller!);
      _setupController();
    }
  }

  void _setupController();

  // One key per tab, not per index, so a tab moved by a routes change keeps
  // its state. Global, because IndexedStack wraps each child in a widget
  // without a key, so a local key can't take the tab's state to its new index.
  final _tabKeys = <LocalKey, GlobalKey>{};

  GlobalKey _tabKeyOf(AutoRoutePage<Object?> page) {
    if (_tabKeys.length > _controller!.pageCount) {
      final matchIds = {
        for (final tab in _controller!.stack) tab.routeData.matchId,
      };
      _tabKeys.removeWhere((matchId, _) => !matchIds.contains(matchId));
    }
    return _tabKeys.putIfAbsent(page.routeData.matchId, GlobalKey.new);
  }

  /// A callback that is called before a tab activates
  /// subclasses can override this to preload the widget
  /// associated with the tab
  bool onPreload(int index);

  @override
  void dispose() {
    if (_controller != null) {
      _controller!.dispose();
      _parentController.removeChildController(_controller!);
      _controller = null;
    }
    super.dispose();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<TabsRouter>('controller', _controller))
      ..add(
        DiagnosticsProperty<RoutingController>(
          'parentController',
          _parentController,
        ),
      )
      ..add(
        DiagnosticsProperty<List<NavigatorObserver>>(
          'navigatorObservers',
          _navigatorObservers,
        ),
      );
  }
}

mixin _RouteAwareTabsMixin<T extends StatefulWidget> on State<T> {
  List<NavigatorObserver> get observers;

  List<RouteMatch<Object?>> get routes;

  void _didInitTabRoute(int index, [int previous = -1]) {
    final routeInfo = routes.elementAtOrNull(index);
    if (routeInfo == null) return;
    final previousInfo = routes.elementAtOrNull(previous);
    observers.whereType<AutoRouterObserver>().forEach((observer) {
      observer.didInitTabRoute(
        TabPageRoute(routeInfo: routeInfo, index: index),
        previousInfo == null
            ? null
            : TabPageRoute(routeInfo: previousInfo, index: previous),
      );
    });
  }

  // The tabs built with the router: the active one, or every one when they
  // don't load lazily, as the IndexedStack tabs report them.
  void _didInitTabRoutes({required bool lazyLoad, required int activeIndex}) {
    if (lazyLoad) {
      _didInitTabRoute(activeIndex);
      return;
    }
    for (var i = 0; i < routes.length; i++) {
      _didInitTabRoute(i);
    }
  }

  void _didChangeTabRoute(int index, int previous) {
    final routeInfo = routes.elementAtOrNull(index);
    final previousInfo = routes.elementAtOrNull(previous);
    if (routeInfo == null || previousInfo == null) return;
    observers.whereType<AutoRouterObserver>().forEach((observer) {
      observer.didChangeTabRoute(
        TabPageRoute(routeInfo: routeInfo, index: index),
        TabPageRoute(routeInfo: previousInfo, index: previous),
      );
    });
  }
}
