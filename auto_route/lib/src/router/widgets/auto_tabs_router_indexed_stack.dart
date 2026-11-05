part of 'auto_tabs_router.dart';

// -----------------------------------------------------------
class _AutoTabsRouterIndexedStack extends AutoTabsRouter {
  const new({
    super.key,
    super.routes,
    this.lazyLoad = true,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.ease,
    this.builder,
    this.transitionBuilder = _defaultTransitionBuilder,
    super.homeIndex,
    super.backThroughHistory,
    super.inheritNavigatorObservers,
    super.navigatorObservers,
  }) : super._();
  final AnimatedIndexedStackBuilder? builder;
  final AnimatedIndexedStackTransitionBuilder transitionBuilder;
  final Duration duration;
  final Curve curve;
  final bool lazyLoad;

  static Widget _defaultTransitionBuilder(BuildContext _, Widget child, Animation<double> animation) {
    return FadeTransition(opacity: animation, child: child);
  }

  @override
  _AutoTabsRouterIndexedStackState createState() => .new();
}

class _AutoTabsRouterIndexedStackState extends AutoTabsRouterState<_AutoTabsRouterIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late CurvedAnimation _curvedAnimation;
  late Animation<double> _animation;
  int _index = 0;
  late int _tabsHash;
  final _indexedStackKey = GlobalKey<_IndexedStackBuilderState>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: widget.duration);
    _curvedAnimation = CurvedAnimation(parent: _animationController, curve: widget.curve);
    _animation = Tween<double>(begin: 0, end: 1).animate(_curvedAnimation);
    _tabsHash = const ListEquality<Object?>().hash(widget.routes);
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTabsChanged);
    _curvedAnimation.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  bool onPreload(int index) {
    return _indexedStackKey.currentState?.preload(index) == true;
  }

  @override
  void _setupController() {
    assert(_controller != null, 'The tabs controller is not set up yet.');
    _controller!.setupRoutes(widget.routes);
    _index = _controller!.activeIndex;
    _animationController.value = 1.0;
    _controller!.addListener(_onTabsChanged);
  }

  void _onTabsChanged() {
    if (_controller!.activeIndex != _index) {
      setState(() {
        _index = _controller!.activeIndex;
      });
      _animationController.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(covariant _AutoTabsRouterIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!const ListEquality<Object?>().equals(widget.routes, oldWidget.routes)) {
      _controller!.replaceAll(widget.routes, _index);
      _tabsHash = const ListEquality<Object?>().hash(widget.routes);
      // didUpdateWidget is always followed by build, so no setState.
      _index = _controller!.activeIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(_controller != null, 'The tabs controller is not set up yet.');
    // Rebuilds whenever the tabs router changes, as its stack or its state.
    return ListenableBuilder(
      listenable: _controller!,
      builder: (stackContext, _) {
        final stack = _controller!.stack;
        final builder = widget.builder ?? _defaultBuilder;
        final stateHash = controller!.stateHash;

        final builderChild = stack.isEmpty
            // A Container with no child fills its space; a ColoredBox would shrink to nothing.
            ? Container(color: Theme.of(stackContext).scaffoldBackgroundColor)
            : _IndexedStackBuilder(
                key: _indexedStackKey,
                activeIndex: _index,
                tabsHash: _tabsHash,
                lazyLoad: widget.lazyLoad,
                navigatorObservers: _navigatorObservers,
                itemBuilder: (context, index) {
                  return KeepAliveTab(key: _tabKeyOf(stack[index]), page: stack[index]);
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
            child: Builder(
              builder: (context) {
                return builder(
                  context,
                  AnimatedBuilder(
                    animation: _animation,
                    child: builderChild,
                    builder: (context, child) {
                      return widget.transitionBuilder(context, child!, _animation);
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _defaultBuilder(BuildContext _, Widget child) {
    return child;
  }
}
