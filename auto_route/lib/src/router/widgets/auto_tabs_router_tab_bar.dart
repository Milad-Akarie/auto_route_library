part of 'auto_tabs_router.dart';

class _AutoTabsRouterTabBar extends AutoTabsRouter {
  const new({
    super.key,
    super.routes,
    this.scrollDirection = Axis.horizontal,
    this.builder,
    this.lazyLoad = true,
    super.homeIndex,
    super.backThroughHistory,
    this.duration,
    this.curve = Curves.ease,
    super.inheritNavigatorObservers,
    super.navigatorObservers,
    this.physics,
    this.dragStartBehavior = DragStartBehavior.start,
  }) : super._();
  final AutoTabsTabBarBuilder? builder;
  final bool lazyLoad;
  final Duration? duration;
  final Curve curve;
  final ScrollPhysics? physics;
  final DragStartBehavior dragStartBehavior;
  final Axis scrollDirection;

  @override
  _AutoTabsRouterTabBarState createState() => .new();
}

class _AutoTabsRouterTabBarState
    extends AutoTabsRouterState<_AutoTabsRouterTabBar>
    with _RouteAwareTabsMixin<_AutoTabsRouterTabBar>, TickerProviderStateMixin {
  late TabController _tabController;
  final _tabViewKey = GlobalKey<AutoTabViewState>();
  late int _tabsHash = const ListEquality<Object?>().hash(widget.routes);

  @override
  void _setupController() {
    assert(_controller != null, 'The tabs controller is not set up yet.');
    _controller!.setupRoutes(widget.routes);
    _updateTabController();
    _didInitTabRoutes(
      lazyLoad: widget.lazyLoad,
      activeIndex: _controller!.activeIndex,
    );
    _controller!.addListener(_onTabsChanged);
  }

  // Also brings the tab bar back from a tab whose guards kept it out.
  void _onTabsChanged() {
    if (_tabController.index != _controller!.activeIndex) {
      _tabController.animateTo(
        _controller!.activeIndex,
        duration: widget.duration,
        curve: widget.curve,
      );
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTabsChanged);
    _tabController
      ..removeListener(_onTabControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _updateTabController() {
    _tabController = TabController(
      animationDuration: widget.duration,
      initialIndex: _controller!.activeIndex,
      length: _controller!.pageCount,
      vsync: this,
    );
    _tabController.addListener(_onTabControllerChanged);
  }

  void _onTabControllerChanged() {
    _controller!.setActiveIndex(_tabController.index);
  }

  @override
  void didUpdateWidget(covariant _AutoTabsRouterTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!const ListEquality<Object?>().equals(
      widget.routes,
      oldWidget.routes,
    )) {
      _controller!.replaceAll(widget.routes, _tabController.index);
      _tabsHash = const ListEquality<Object?>().hash(widget.routes);
      final oldTabController = _tabController
        ..removeListener(_onTabControllerChanged);
      _updateTabController();
      // Stops its animation, whose listener would otherwise reach this router
      // after it is disposed.
      oldTabController.dispose();
    }
  }

  @override
  bool onPreload(int index) {
    final didPreload = _tabViewKey.currentState?.preload(index) == true;

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
    assert(_controller != null, 'The tabs controller is not set up yet.');
    // Rebuilds whenever the tabs router changes, as its stack or its state.
    return ListenableBuilder(
      listenable: _controller!,
      builder: (_, _) {
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
                    scrollDirection: widget.scrollDirection,
                    physics: widget.physics,
                    dragStartBehavior: widget.dragStartBehavior,
                    controller: _tabController,
                    router: _controller!,
                    lazyLoad: widget.lazyLoad,
                  ),
                  _tabController,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _defaultPageViewBuilder(
    BuildContext _,
    Widget child,
    TabController _,
  ) {
    return child;
  }

  @override
  List<NavigatorObserver> get observers => _navigatorObservers;

  @override
  List<RouteMatch<Object?>> get routes =>
      _controller!.stackData.map((e) => e.route).toList();
}
