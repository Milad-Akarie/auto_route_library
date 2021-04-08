import 'package:auto_route/src/route/route_data_scope.dart';
import 'package:auto_route/src/route/page_route_info.dart';
import 'package:auto_route/src/router/controller/controller_scope.dart';
import 'package:auto_route/src/router/controller/routing_controller.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../../auto_route.dart';
import '../controller/routing_controller.dart';

typedef AnimatedIndexedStackBuilder = Widget Function(BuildContext context, Widget child, Animation<double> animation);

class AutoTabsRouter extends StatefulWidget {
  final AnimatedIndexedStackBuilder? builder;
  final List<PageRouteInfo> routes;
  final Duration duration;
  final Curve curve;
  final bool lazyLoad;

  const AutoTabsRouter({
    Key? key,
    required this.routes,
    this.lazyLoad = true,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.ease,
    this.builder,
  }) : super(key: key);

  @override
  AutoTabsRouterState createState() => AutoTabsRouterState();

  static TabsRouter of(BuildContext context) {
    var scope = TabsRouterScope.of(context);
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

class AutoTabsRouterState extends State<AutoTabsRouter> with SingleTickerProviderStateMixin {
  TabsRouter? _controller;
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _index = 0;

  TabsRouter? get controller => _controller;

  @override
  void initState() {
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
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      // var entry = StackEntryScope.of(context);
      // assert(entry is TabsRouter);
      // _controller = entry as TabsRouter;

      final parent = RoutingControllerScope.of(context);
      final parentRoute = RouteDataScope.of(context);
      _controller = parent.findOrCreateChildController<TabsRouter>(parentRoute) as TabsRouter;

      _resetController();
    }
  }

  void _resetController() {
    assert(_controller != null);
    _controller!.setupRoutes(widget.routes);
    _index = _controller!.activeIndex;
    _animationController.value = 1.0;
    var rootDelegate = AutoRouterDelegate.of(context);
    _controller!.addListener(() {
      if (_controller!.activeIndex != _index) {
        rootDelegate.notify(_controller!);
        setState(() {
          _index = _controller!.activeIndex;
        });
        _animationController.forward(from: 0.0);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    // _controller?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AutoTabsRouter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!ListEquality().equals(widget.routes, oldWidget.routes)) {
      _resetController();
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(_controller != null);
    final stack = _controller!.stack;
    final builder = widget.builder ?? _defaultBuilder;

    final builderChild = stack.isEmpty
        ? Container(color: Theme.of(context).scaffoldBackgroundColor)
        : _IndexedStackBuilder(
            activeIndex: _index,
            lazyLoad: widget.lazyLoad,
            itemCount: stack.length,
            itemBuilder: (BuildContext context, int index) {
              return stack[index].wrappedChild(context);
            },
          );

    return RoutingControllerScope(
      controller: _controller!,
      child: TabsRouterScope(
          controller: _controller!,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) => builder(context, child ?? builderChild, _animation),
            child: builderChild,
          )),
    );
  }

  Widget _defaultBuilder(_, child, animation) {
    return FadeTransition(opacity: animation, child: child);
  }
}

class _IndexedStackBuilder extends StatefulWidget {
  final int activeIndex;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final bool lazyLoad;

  const _IndexedStackBuilder({
    Key? key,
    required this.activeIndex,
    required this.itemBuilder,
    this.itemCount = 0,
    required this.lazyLoad,
  }) : super(key: key);

  @override
  _IndexedStackBuilderState createState() => _IndexedStackBuilderState();
}

class _DummyWidget extends SizedBox {
  const _DummyWidget() : super(width: 0.0, height: 0.0);
}

class _IndexedStackBuilderState extends State<_IndexedStackBuilder> {
  final _dummyWidget = const _DummyWidget();
  final _pages = <Widget>[];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.itemCount; ++i) {
      if (i == widget.activeIndex || !widget.lazyLoad) {
        _pages.add(widget.itemBuilder(context, i));
      } else {
        _pages.add(_dummyWidget);
      }
    }
  }

  @override
  void didUpdateWidget(_IndexedStackBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lazyLoad && _pages[widget.activeIndex] is _DummyWidget) {
      _pages[widget.activeIndex] = widget.itemBuilder(context, widget.activeIndex);
    }
  }

  @override
  Widget build(BuildContext context) => IndexedStack(
        index: widget.activeIndex,
        sizing: StackFit.expand,
        children: _pages,
      );
}
