part of 'auto_tabs_router.dart';

class _AutoTabsRouterPageView extends AutoTabsRouter {
  const new({
    super.key,
    super.routes,
    AutoTabsPageViewBuilder? builder,
    this.lazyLoad = true,
    super.homeIndex,
    super.backThroughHistory,
    this.scrollDirection = Axis.horizontal,
    this.animatePageTransition = true,
    this.duration = kTabScrollDuration,
    this.curve = Curves.easeInOut,
    this.physics,
    this.dragStartBehavior = DragStartBehavior.start,
    super.inheritNavigatorObservers,
    super.navigatorObservers,
  }) : _pageViewModeBuilder = builder,
       super._();
  final AutoTabsPageViewBuilder? _pageViewModeBuilder;
  final bool lazyLoad;
  final bool animatePageTransition;
  final Duration duration;
  final Curve curve;
  final Axis scrollDirection;
  final ScrollPhysics? physics;
  final DragStartBehavior dragStartBehavior;

  @override
  _AutoTabsRouterPageViewState createState() => .new();
}

class _AutoTabsRouterPageViewState
    extends AutoTabsRouterState<_AutoTabsRouterPageView>
    with _RouteAwareTabsMixin<_AutoTabsRouterPageView> {
  late PageController _pageController;
  final _pageViewKey = GlobalKey<AutoPageViewState>();

  @override
  void _setupController() {
    assert(_controller != null, 'The tabs controller is not set up yet.');
    _controller!.setupRoutes(widget.routes);
    _updatePageController();
    _didInitTabRoutes(
      lazyLoad: widget.lazyLoad,
      activeIndex: _controller!.activeIndex,
    );
  }

  void _updatePageController() {
    _pageController = PageController(initialPage: _controller!.activeIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  bool onPreload(int index) {
    final didPreload = _pageViewKey.currentState?.preload(index) == true;
    if (index != _controller!.activeIndex) {
      if (didPreload) {
        _didInitTabRoute(index, _controller!.activeIndex);
      } else {
        _didChangeTabRoute(index, _controller!.activeIndex);
      }
    }

    return didPreload;
  }

  late int _tabsHash = const ListEquality<Object?>().hash(widget.routes);

  @override
  void didUpdateWidget(covariant _AutoTabsRouterPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!const ListEquality<Object?>().equals(
      widget.routes,
      oldWidget.routes,
    )) {
      _controller!.replaceAll(widget.routes, _controller!.activeIndex);
      _tabsHash = const ListEquality<Object?>().hash(widget.routes);
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(_controller != null, 'The tabs controller is not set up yet.');
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
                lazyLoad: widget.lazyLoad,
              ),
              _pageController,
            );
          },
        ),
      ),
    );
  }

  Widget _defaultPageViewBuilder(
    BuildContext _,
    Widget child,
    PageController _,
  ) {
    return child;
  }

  @override
  List<NavigatorObserver> get observers => _navigatorObservers;

  @override
  List<RouteMatch<Object?>> get routes =>
      _controller!.stackData.map((e) => e.route).toList();
}
