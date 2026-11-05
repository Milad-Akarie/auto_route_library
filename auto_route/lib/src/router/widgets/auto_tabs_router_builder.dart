part of 'auto_tabs_router.dart';

class _AutoTabsRouterBuilder extends AutoTabsRouter {
  const new({
    required this.builder,
    super.key,
    super.routes,
    this.onNavigate,
    this.onRouterReady,
    super.homeIndex,
    super.backThroughHistory,
    super.inheritNavigatorObservers,
    super.navigatorObservers,
  }) : super._();
  final AutoTabsBuilder builder;
  final OnNavigationChanged? onNavigate;
  final OnNavigationChanged? onRouterReady;

  @override
  _AutoTabsRouterBuilderState createState() => .new();
}

class _AutoTabsRouterBuilderState extends AutoTabsRouterState<_AutoTabsRouterBuilder>
    with _RouteAwareTabsMixin<_AutoTabsRouterBuilder> {
  @override
  void _setupController() {
    assert(_controller != null, 'The tabs controller is not set up yet.');

    _controller!.setupRoutes(widget.routes);
    widget.onRouterReady?.call(_controller!);
    _didInitTabRoute(_controller!.activeIndex);
    _controller!.addListener(_onTabsChanged);
  }

  void _onTabsChanged() {
    if (_controller!.activeIndex != _controller!.previousIndex) {
      _didChangeTabRoute(_controller!.activeIndex, _controller!.previousIndex ?? 0);
      widget.onNavigate?.call(_controller!);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTabsChanged);
    super.dispose();
  }

  @override
  bool onPreload(int index) => false;

  @override
  void didUpdateWidget(covariant _AutoTabsRouterBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!const ListEquality<Object?>().equals(widget.routes, oldWidget.routes)) {
      _controller!.replaceAll(widget.routes, _controller!.activeIndex);
      widget.onNavigate?.call(_controller!);
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(_controller != null, 'The tabs controller is not set up yet.');
    // Rebuilds whenever the tabs router changes, as its stack or its state.
    return ListenableBuilder(
      listenable: _controller!,
      builder: (_, _) {
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
            child: Builder(
              builder: (context) {
                return builder(
                  context,
                  List.generate(
                    stack.length,
                    (index) => KeepAliveTab(key: _tabKeyOf(stack[index]), page: stack[index]),
                  ),
                  _controller!,
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  List<NavigatorObserver> get observers => _navigatorObservers;

  @override
  List<RouteMatch<Object?>> get routes => _controller!.stackData.map((e) => e.route).toList();
}
