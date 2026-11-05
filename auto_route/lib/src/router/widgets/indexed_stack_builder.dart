part of 'auto_tabs_router.dart';

class _IndexedStackBuilder extends StatefulWidget {
  const new({
    required this.activeIndex,
    required this.itemBuilder,
    required this.navigatorObservers,
    required this.stack,
    required this.lazyLoad,
    required this.tabsHash,
    super.key,
  });

  final int activeIndex;
  final IndexedWidgetBuilder itemBuilder;
  final bool lazyLoad;
  final List<AutoRoutePage<Object?>> stack;
  final List<NavigatorObserver> navigatorObservers;
  final int tabsHash;

  @override
  _IndexedStackBuilderState createState() => .new();
}

class _IndexedStackBuilderState extends State<_IndexedStackBuilder>
    with _RouteAwareTabsMixin<_IndexedStackBuilder> {
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
    setState(() => _initializedPagesTracker[index] = true);
    return true;
  }

  @override
  List<RouteMatch<Object?>> get routes =>
      widget.stack.map((e) => e.routeData.route).toList();

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
      final initializedPages = {
        for (final entry in _initializedPagesTracker.entries)
          if (entry.value) ?oldWidget.stack.elementAtOrNull(entry.key),
      };
      _initializedPagesTracker.clear();
      _setup();
      // Tabs kept across the routes change stay loaded.
      for (var i = 0; i < widget.stack.length; ++i) {
        if (initializedPages.contains(widget.stack[i])) {
          _initializedPagesTracker[i] = true;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: IndexedStack(
        index: widget.activeIndex,
        sizing: .expand,
        children: List.generate(widget.stack.length, (index) {
          if (!widget.stack[index].maintainState &&
              index != widget.activeIndex) {
            _initializedPagesTracker[index] = false;
          }
          final isInitialized = _initializedPagesTracker[index] == true;
          final child = isInitialized
              ? widget.itemBuilder(context, index)
              : _dummyWidget;
          final isInactive = index != widget.activeIndex;

          // Always wrap with ExcludeSemantics and ExcludeFocus but control with excluding property
          return ExcludeSemantics(
            // Keyed by page so a tab kept across a routes change keeps its state
            key: ObjectKey(widget.stack[index]),
            excluding: isInactive,
            child: ExcludeFocus(excluding: isInactive, child: child),
          );
        }),
      ),
    );
  }
}
