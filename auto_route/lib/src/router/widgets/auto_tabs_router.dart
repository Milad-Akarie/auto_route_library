import 'package:auto_route/src/router/widgets/auto_tab_view.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../auto_route.dart';

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
typedef OnNavigationChanged = Function(TabsRouter tabsRouter);

/// An implementation of a router widget that handles parallel routeing
abstract class AutoTabsRouter extends StatefulWidget {
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

  const AutoTabsRouter._({
    super.key,
    required this.routes,
    this.homeIndex = -1,
    this.inheritNavigatorObservers = true,
    this.navigatorObservers = AutoRouterDelegate.defaultNavigatorObserversBuilder,
  });

  /// Builds an [AutoTabsRouter] to uses
  /// a [IndexedStack] to render pages
  const factory AutoTabsRouter({
    Key? key,
    List<PageRouteInfo>? routes,
    bool lazyLoad,
    Duration duration,
    Curve curve,
    AnimatedIndexedStackBuilder? builder,
    AnimatedIndexedStackTransitionBuilder transitionBuilder,
    int homeIndex,
    bool inheritNavigatorObservers,
    NavigatorObserversBuilder navigatorObservers,
  }) = _AutoTabsRouterIndexedStack;

  /// Builds an [AutoTabsRouter] to uses
  /// a [PageView] to render pages
  const factory AutoTabsRouter.pageView({
    Key? key,
    List<PageRouteInfo>? routes,
    AutoTabsPageViewBuilder? builder,
    int homeIndex,
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
  /// a [TabView] to render pages
  const factory AutoTabsRouter.tabBar({
    Key? key,
    List<PageRouteInfo>? routes,
    AutoTabsTabBarBuilder? builder,
    int homeIndex,
    bool animatePageTransition,
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
  const factory AutoTabsRouter.builder({
    Key? key,
    List<PageRouteInfo>? routes,
    required AutoTabsBuilder builder,
    OnNavigationChanged? onNavigate,
    OnNavigationChanged? onRouterReady,
    int homeIndex,
    bool inheritNavigatorObservers,
    NavigatorObserversBuilder navigatorObservers,
  }) = _AutoTabsRouterBuilder;

  /// Looks up and returns the scoped [controller]
  ///
  /// if watch is true dependent widget will watch changes
  /// of this scope otherwise it would just read it
  ///
  /// throws an error if it does not find it
  static TabsRouter of(BuildContext context, {bool watch = false}) {
    var scope = TabsRouterScope.of(context, watch: watch);
    assert(() {
      if (scope == null) {
        throw FlutterError(
            'AutoTabsRouter operation requested with a context that does not include an AutoTabsRouter.\n'
            'The context used to retrieve the AutoTabsRouter must be that of a widget that '
            'is a descendant of an AutoTabsRouter widget.');
      }
      return true;
    }());
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
    final parentRoute = RouteData.of(context);
    final parentScope = RouterScope.of(context, watch: true);
    if (_controller == null) {
      _inheritableObserversBuilder = () {
        var observers = widget.navigatorObservers();
        if (!widget.inheritNavigatorObservers) {
          return observers;
        }
        var inheritedObservers = parentScope.inheritableObserversBuilder();
        return inheritedObservers + observers;
      };
      _navigatorObservers = _inheritableObserversBuilder();
      _parentController = parentScope.controller;
      _controller = TabsRouter(
        parent: _parentController,
        key: parentRoute.key,
        matchId: parentRoute.matchId,
        homeIndex: widget.homeIndex,
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
    properties.add(DiagnosticsProperty<TabsRouter>('controller', _controller));
    properties.add(DiagnosticsProperty<RoutingController>('parentController', _parentController));
    properties.add(DiagnosticsProperty<List<NavigatorObserver>>('navigatorObservers', _navigatorObservers));
  }
}

// -----------------------------------------------------------
class _AutoTabsRouterIndexedStack extends AutoTabsRouter {
  final AnimatedIndexedStackBuilder? builder;
  final AnimatedIndexedStackTransitionBuilder transitionBuilder;
  final Duration duration;
  final Curve curve;
  final bool lazyLoad;

  static Widget _defaultTransitionBuilder(BuildContext _, Widget child, Animation<double> animation) {
    return FadeTransition(opacity: animation, child: child);
  }

  const _AutoTabsRouterIndexedStack({
    super.key,
    super.routes,
    this.lazyLoad = true,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.ease,
    this.builder,
    this.transitionBuilder = _defaultTransitionBuilder,
    super.homeIndex,
    super.inheritNavigatorObservers,
    super.navigatorObservers,
  }) : super._();

  @override
  _AutoTabsRouterIndexedStackState createState() => _AutoTabsRouterIndexedStackState();
}

class _AutoTabsRouterIndexedStackState extends AutoTabsRouterState<_AutoTabsRouterIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _index = 0;
  late int _tabsHash;
  final _indexedStackKey = GlobalKey<_IndexedStackBuilderState>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: widget.curve,
      ),
    );
    _tabsHash = const ListEquality().hash(widget.routes);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  bool onPreload(int index) {
    final didPreload = _indexedStackKey.currentState?.preload(index) == true;
    if (didPreload & mounted) {
      setState(() {});
    }
    return didPreload;
  }

  @override
  void _setupController() {
    assert(_controller != null);
    _controller!.setupRoutes(widget.routes);
    _index = _controller!.activeIndex;
    _animationController.value = 1.0;
    _controller!.addListener(() {
      if (_controller!.activeIndex != _index) {
        setState(() {
          _index = _controller!.activeIndex;
        });
        _animationController.forward(from: 0.0);
      } else if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(covariant _AutoTabsRouterIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!const ListEquality().equals(widget.routes, oldWidget.routes)) {
      _controller!.replaceAll(widget.routes, _index);
      _tabsHash = const ListEquality().hash(widget.routes);
      setState(() {
        _index = _controller!.activeIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(_controller != null);
    final stack = _controller!.stack;
    final builder = widget.builder ?? _defaultBuilder;
    final stateHash = controller!.stateHash;

    final builderChild = stack.isEmpty
        ? Container(color: Theme.of(context).scaffoldBackgroundColor)
        : _IndexedStackBuilder(
            key: _indexedStackKey,
            activeIndex: _index,
            tabsHash: _tabsHash,
            lazyLoad: widget.lazyLoad,
            animation: _animation,
            navigatorObservers: _navigatorObservers,
            itemBuilder: (BuildContext context, int index) {
              return stack[index].buildPage(context);
            },
            stack: stack,
          );

    return RouterScope(
      controller: _controller!,
      inheritableObserversBuilder: _inheritableObserversBuilder,
      stateHash: stateHash,
      navigatorObservers: _navigatorObservers,
      child: TabsRouterScope(
        controller: _controller!,
        stateHash: stateHash,
        child: Builder(builder: (context) {
          return builder(
            context,
            AnimatedBuilder(
              animation: _animation,
              child: builderChild,
              builder: (context, child) {
                return widget.transitionBuilder(
                  context,
                  child!,
                  _animation,
                );
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _defaultBuilder(BuildContext _, Widget child) {
    return child;
  }
}

class _IndexedStackBuilder extends StatefulWidget {
  const _IndexedStackBuilder({
    required this.activeIndex,
    required this.itemBuilder,
    required this.navigatorObservers,
    required this.stack,
    required this.lazyLoad,
    required this.tabsHash,
    required this.animation,
    super.key,
  });

  final int activeIndex;
  final IndexedWidgetBuilder itemBuilder;
  final bool lazyLoad;
  final List<AutoRoutePage> stack;
  final List<NavigatorObserver> navigatorObservers;
  final int tabsHash;
  final Animation<double> animation;

  @override
  _IndexedStackBuilderState createState() => _IndexedStackBuilderState();
}

class _IndexedStackBuilderState extends State<_IndexedStackBuilder> with _RouteAwareTabsMixin<_IndexedStackBuilder> {
  final _dummyWidget = const SizedBox.shrink();
  final _initializedPagesTracker = <int, bool>{};

  bool preload(int index) {
    if (_initializedPagesTracker[index] == true) {
      if (index != widget.activeIndex) {
        _didChangeTabRoute(index, widget.activeIndex);
      }
      return false;
    }
    if (widget.lazyLoad) {
      _didInitTabRoute(index, widget.activeIndex);
    }
    return _initializedPagesTracker[index] = true;
  }

  @override
  List<RouteMatch> get routes => widget.stack.map((e) => e.routeData.route).toList();

  @override
  List<NavigatorObserver> get observers => widget.navigatorObservers;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() {
    for (var i = 0; i < widget.stack.length; ++i) {
      if (i == widget.activeIndex || !widget.lazyLoad) {
        _initializedPagesTracker[i] = true;
        _didInitTabRoute(i);
      } else {
        _initializedPagesTracker[i] = false;
      }
    }
  }

  @override
  void didUpdateWidget(_IndexedStackBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tabsHash != oldWidget.tabsHash) {
      _initializedPagesTracker.clear();
      _setup();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: IndexedStack(
        key: ValueKey(widget.tabsHash),
        index: widget.activeIndex,
        sizing: StackFit.expand,
        children: List.generate(
          widget.stack.length,
          (index) {
            if (!widget.stack[index].maintainState && index != widget.activeIndex) {
              _initializedPagesTracker[index] = false;
            }
            final isInitialized = _initializedPagesTracker[index] == true;
            final child = isInitialized ? widget.itemBuilder(context, index) : _dummyWidget;
            final isInactive = index != widget.activeIndex;

            // Always wrap with ExcludeSemantics and ExcludeFocus but control with excluding property
            return ExcludeSemantics(
              excluding: isInactive,
              child: ExcludeFocus(
                excluding: isInactive,
                child: child,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AutoTabsRouterPageView extends AutoTabsRouter {
  final AutoTabsPageViewBuilder? _pageViewModeBuilder;
  final bool animatePageTransition;
  final Duration duration;
  final Curve curve;
  final Axis scrollDirection;
  final ScrollPhysics? physics;
  final DragStartBehavior dragStartBehavior;

  const _AutoTabsRouterPageView({
    super.key,
    super.routes,
    AutoTabsPageViewBuilder? builder,
    super.homeIndex,
    this.scrollDirection = Axis.horizontal,
    this.animatePageTransition = true,
    this.duration = kTabScrollDuration,
    this.curve = Curves.easeInOut,
    this.physics,
    this.dragStartBehavior = DragStartBehavior.start,
    super.inheritNavigatorObservers,
    super.navigatorObservers,
  })  : _pageViewModeBuilder = builder,
        super._();

  @override
  _AutoTabsRouterPageViewState createState() => _AutoTabsRouterPageViewState();
}

class _AutoTabsRouterPageViewState extends AutoTabsRouterState<_AutoTabsRouterPageView>
    with _RouteAwareTabsMixin<_AutoTabsRouterPageView> {
  late PageController _pageController;
  final _pageViewKey = GlobalKey<AutoPageViewState>();

  @override
  void _setupController() {
    assert(_controller != null);
    _controller!.setupRoutes(widget.routes);
    _updatePageController();
    _didInitTabRoute(_controller!.activeIndex);
  }

  void _updatePageController() {
    _pageController = PageController(
      initialPage: _controller!.activeIndex,
    );
  }

  @override
  bool onPreload(int index) {
    final didPreload = _pageViewKey.currentState?.preload(index) == true;
    if (didPreload & mounted) {
      setState(() {});
    }
    if (index != _controller!.activeIndex) {
      if (didPreload) {
        _didInitTabRoute(index, _controller!.activeIndex);
      } else {
        _didChangeTabRoute(index, _controller!.activeIndex);
      }
    }

    return didPreload;
  }

  late int _tabsHash = const ListEquality().hash(widget.routes);

  @override
  void didUpdateWidget(covariant _AutoTabsRouterPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!const ListEquality().equals(widget.routes, oldWidget.routes)) {
      _controller!.replaceAll(widget.routes, _controller!.activeIndex);
      _tabsHash = const ListEquality().hash(widget.routes);
      _updatePageController();
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(_controller != null);
    final builder = widget._pageViewModeBuilder ?? _defaultPageViewBuilder;
    final stateHash = controller!.stateHash;
    return RouterScope(
      key: _controller!.globalRouterKey,
      controller: _controller!,
      inheritableObserversBuilder: _inheritableObserversBuilder,
      stateHash: stateHash,
      navigatorObservers: _navigatorObservers,
      child: TabsRouterScope(
        controller: _controller!,
        stateHash: stateHash,
        child: Builder(
            key: ValueKey(_tabsHash),
            builder: (context) {
              return builder(
                context,
                AutoPageView(
                  key: _pageViewKey,
                  animatePageTransition: widget.animatePageTransition,
                  duration: widget.duration,
                  scrollDirection: widget.scrollDirection,
                  physics: widget.physics,
                  dragStartBehavior: widget.dragStartBehavior,
                  controller: _pageController,
                  router: _controller!,
                ),
                _pageController,
              );
            }),
      ),
    );
  }

  Widget _defaultPageViewBuilder(BuildContext _, Widget child, PageController __) {
    return child;
  }

  @override
  List<NavigatorObserver> get observers => _navigatorObservers;

  @override
  List<RouteMatch> get routes => _controller!.stackData.map((e) => e.route).toList();
}

class _AutoTabsRouterTabBar extends AutoTabsRouter {
  final AutoTabsTabBarBuilder? builder;
  final bool animatePageTransition;
  final Duration? duration;
  final Curve curve;
  final ScrollPhysics? physics;
  final DragStartBehavior dragStartBehavior;
  final Axis scrollDirection;

  const _AutoTabsRouterTabBar({
    super.key,
    super.routes,
    this.scrollDirection = Axis.horizontal,
    this.builder,
    super.homeIndex,
    this.animatePageTransition = true,
    this.duration,
    this.curve = Curves.ease,
    super.inheritNavigatorObservers,
    super.navigatorObservers,
    this.physics,
    this.dragStartBehavior = DragStartBehavior.start,
  }) : super._();

  @override
  _AutoTabsRouterTabBarState createState() => _AutoTabsRouterTabBarState();
}

class _AutoTabsRouterTabBarState extends AutoTabsRouterState<_AutoTabsRouterTabBar>
    with _RouteAwareTabsMixin<_AutoTabsRouterTabBar>, TickerProviderStateMixin {
  late TabController _tabController;
  final _tabViewKey = GlobalKey<AutoTabViewState>();
  late int _tabsHash = const ListEquality().hash(widget.routes);

  @override
  void _setupController() {
    assert(_controller != null);
    _controller!.setupRoutes(widget.routes);
    _updateTabController();
    _didInitTabRoute(_controller!.activeIndex);
    _controller!.addListener(() {
      if (_controller!.activeIndex != _controller!.previousIndex) {
        _tabController.animateTo(
          _controller!.activeIndex,
          duration: widget.duration,
          curve: widget.curve,
        );
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateTabController() {
    _tabController = TabController(
      animationDuration: widget.duration,
      initialIndex: _controller!.activeIndex,
      length: _controller!.pageCount,
      vsync: this,
    );
    _tabController.addListener(() {
      _controller!.setActiveIndex(_tabController.index);
    });
  }

  @override
  void didUpdateWidget(covariant _AutoTabsRouterTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!const ListEquality().equals(widget.routes, oldWidget.routes)) {
      _controller!.replaceAll(widget.routes, _tabController.index);
      _tabsHash = const ListEquality().hash(widget.routes);
      _updateTabController();
    }
  }

  @override
  bool onPreload(int index) {
    final didPreload = _tabViewKey.currentState?.preload(index) == true;
    if (didPreload & mounted) {
      setState(() {});
    }

    if (index != _controller!.activeIndex) {
      if (didPreload) {
        _didInitTabRoute(index, _controller!.activeIndex);
      } else {
        _didChangeTabRoute(index, _controller!.activeIndex);
      }
    }

    return didPreload;
  }

  @override
  Widget build(BuildContext context) {
    assert(_controller != null);
    final builder = widget.builder ?? _defaultPageViewBuilder;
    final stateHash = controller!.stateHash;
    return RouterScope(
      key: _controller!.globalRouterKey,
      controller: _controller!,
      inheritableObserversBuilder: _inheritableObserversBuilder,
      stateHash: stateHash,
      navigatorObservers: _navigatorObservers,
      child: TabsRouterScope(
        controller: _controller!,
        stateHash: stateHash,
        child: Builder(
            key: ValueKey(_tabsHash),
            builder: (context) {
              return builder(
                context,
                AutoTabView(
                  key: _tabViewKey,
                  animatePageTransition: widget.animatePageTransition,
                  scrollDirection: widget.scrollDirection,
                  physics: widget.physics,
                  dragStartBehavior: widget.dragStartBehavior,
                  controller: _tabController,
                  router: _controller!,
                ),
                _tabController,
              );
            }),
      ),
    );
  }

  Widget _defaultPageViewBuilder(BuildContext _, Widget child, TabController __) {
    return child;
  }

  @override
  List<NavigatorObserver> get observers => _navigatorObservers;

  @override
  List<RouteMatch> get routes => _controller!.stackData.map((e) => e.route).toList();
}

class _AutoTabsRouterBuilder extends AutoTabsRouter {
  final AutoTabsBuilder builder;
  final OnNavigationChanged? onNavigate;
  final OnNavigationChanged? onRouterReady;

  const _AutoTabsRouterBuilder({
    super.key,
    super.routes,
    this.onNavigate,
    this.onRouterReady,
    required this.builder,
    super.homeIndex,
    super.inheritNavigatorObservers,
    super.navigatorObservers,
  }) : super._();

  @override
  _AutoTabsRouterBuilderState createState() => _AutoTabsRouterBuilderState();
}

class _AutoTabsRouterBuilderState extends AutoTabsRouterState<_AutoTabsRouterBuilder>
    with _RouteAwareTabsMixin<_AutoTabsRouterBuilder> {
  @override
  void _setupController() {
    assert(_controller != null);

    _controller!.setupRoutes(widget.routes);
    widget.onRouterReady?.call(_controller!);
    _didInitTabRoute(_controller!.activeIndex);
    _controller!.addListener(() {
      if (_controller!.activeIndex != _controller!.previousIndex) {
        _didChangeTabRoute(_controller!.activeIndex, _controller!.previousIndex ?? 0);
        widget.onNavigate?.call(_controller!);
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  bool onPreload(int index) => false;

  @override
  void didUpdateWidget(covariant _AutoTabsRouterBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!const ListEquality().equals(widget.routes, oldWidget.routes)) {
      _controller!.replaceAll(widget.routes, _controller!.activeIndex);
      widget.onNavigate?.call(_controller!);
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(_controller != null);
    final stack = _controller!.stack;
    final builder = widget.builder;
    final stateHash = controller!.stateHash;
    return RouterScope(
      key: _controller!.globalRouterKey,
      controller: _controller!,
      inheritableObserversBuilder: _inheritableObserversBuilder,
      stateHash: stateHash,
      navigatorObservers: _navigatorObservers,
      child: TabsRouterScope(
        controller: _controller!,
        stateHash: stateHash,
        child: Builder(builder: (context) {
          return builder(
            context,
            List.generate(
              stack.length,
              (index) => KeepAliveTab(
                key: ValueKey(index),
                page: stack[index],
              ),
            ),
            _controller!,
          );
        }),
      ),
    );
  }

  @override
  List<NavigatorObserver> get observers => _navigatorObservers;

  @override
  List<RouteMatch> get routes => _controller!.stackData.map((e) => e.route).toList();
}

mixin _RouteAwareTabsMixin<T extends StatefulWidget> on State<T> {
  List<NavigatorObserver> get observers;

  List<RouteMatch> get routes;

  void _didInitTabRoute(int index, [int previous = -1]) {
    observers.whereType<AutoRouterObserver>().forEach((observer) {
      TabPageRoute? previousRoute;
      if (previous != -1) {
        previousRoute = TabPageRoute(routeInfo: routes[previous], index: previous);
      }
      observer.didInitTabRoute(
        TabPageRoute(routeInfo: routes[index], index: index),
        previousRoute,
      );
    });
  }

  void _didChangeTabRoute(int index, int previous) {
    observers.whereType<AutoRouterObserver>().forEach((observer) {
      observer.didChangeTabRoute(
        TabPageRoute(routeInfo: routes[index], index: index),
        TabPageRoute(routeInfo: routes[previous], index: previous),
      );
    });
  }
}

/// A Wrapper widget to utilize [AutomaticKeepAliveClientMixin]
class KeepAliveTab extends StatefulWidget {
  /// Default contractor
  const KeepAliveTab({
    super.key,
    required this.page,
    this.initiallyLoaded = true,
  });

  /// Whether the tab should be initially loaded
  final bool initiallyLoaded;

  /// The tab page to keep-alive
  final AutoRoutePage page;

  @override
  State<KeepAliveTab> createState() => KeepAliveTabState();
}

/// The state of [KeepAliveTab]
class KeepAliveTabState extends State<KeepAliveTab> with AutomaticKeepAliveClientMixin {
  late bool _load = widget.initiallyLoaded;

  /// preloads the tab so other navigation actions can be done
  /// before the tab is initialized
  bool preload() {
    if (_load) return false;
    setState(() {
      _load = true;
    });
    return true;
  }

  /// unloads the tab if it's not needed
  void unloadIfRequired() {
    if (_load && !widget.page.maintainState) {
      setState(() {
        _load = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _load ? widget.page.buildPage(context) : const SizedBox.shrink();
  }

  @override
  bool get wantKeepAlive => widget.page.maintainState;
}
