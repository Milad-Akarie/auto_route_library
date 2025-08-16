import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'eager_page_view.dart';

/// Most of the code here is taking from flutter's [TabView]
class AutoPageView extends StatefulWidget {
  /// Default constructor
  const AutoPageView({
    super.key,
    required this.animatePageTransition,
    this.duration = const Duration(milliseconds: 300),
    required this.controller,
    this.physics,
    required this.router,
    this.dragStartBehavior = DragStartBehavior.start,
    this.scrollDirection = Axis.horizontal,
  });

  /// Whether to use [PageController.animateToPage] or [PageController.jumpToPage]
  final bool animatePageTransition;

  /// The duration of the transition animation passed to [PageController.animateToPage]
  final Duration duration;

  /// The page controller used by [PageView]
  /// see [PageView.controller]
  final PageController controller;

  /// The scroll direction of the [PageView]
  /// see [PageView.scrollDirection]
  final Axis scrollDirection;

  /// An object that controllers what page to display
  /// and navigates from one page to another
  final TabsRouter router;

  /// How the page view should respond to user input.
  ///
  /// For example, determines how the page view continues to animate after the
  /// user stops dragging the page view.
  ///
  /// The physics are modified to snap to page boundaries using
  /// [PageScrollPhysics] prior to being used.
  ///
  /// Defaults to matching platform conventions.
  final ScrollPhysics? physics;

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  @override
  State<AutoPageView> createState() => AutoPageViewState();
}

/// State implementation of [AutoPageView]
class AutoPageViewState extends State<AutoPageView> {
  late final PageController _controller = widget.controller;
  late final TabsRouter _router = widget.router;
  late List<Widget> _children;
  int _warpUnderwayCount = 0;
  final _tabKeys = <int, GlobalKey<KeepAliveTabState>>{};

  @override
  void initState() {
    super.initState();
    _updateChildren();
    _router.addListener(_routerListener);
  }

  @override
  void didUpdateWidget(AutoPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller.jumpToPage(_router.activeIndex);
    }
  }

  @override
  void dispose() {
    _router.removeListener(_routerListener);
    super.dispose();
  }

  void _routerListener() {
    _updateChildren();
    _disposeInactiveChildren();
    if (_router.activeIndex != _controller.page!.round()) {
      _warpToCurrentIndex();
    }
  }

  /// Preload the page at [index]
  bool preload(int index) {
    final didPreload = _tabKeys[index]?.currentState?.preload() == true;
    if (didPreload) {
      _updateChildren();
    }
    return didPreload;
  }

  void _updateChildren() {
    final stack = widget.router.stack;
    _children = List.generate(
      stack.length,
      (index) => KeepAliveTab(
        key: _tabKeys.putIfAbsent(index, () => GlobalKey()),
        initiallyLoaded: _router.activeIndex == index,
        page: stack[index],
      ),
    );
  }

  void _disposeInactiveChildren() {
    for (int i = 0; i < _tabKeys.length; i++) {
      if (i != _router.activeIndex) {
        _tabKeys[i]?.currentState?.unloadIfRequired();
      }
    }
  }

  Future<void> _warpToCurrentIndex() async {
    if (!mounted) return Future<void>.value();

    final Duration duration = widget.duration;
    final bool animatePageTransition = widget.animatePageTransition;

    final int previousIndex = _router.previousIndex ?? 0;
    if ((_router.activeIndex - previousIndex).abs() == 1) {
      _warpUnderwayCount += 1;
      if (animatePageTransition) {
        await _controller.animateToPage(_router.activeIndex, duration: duration, curve: Curves.ease);
      } else {
        _controller.jumpToPage(_router.activeIndex);
      }
      _warpUnderwayCount -= 1;
      return Future<void>.value();
    }
    assert((_router.activeIndex - previousIndex).abs() > 1);
    final int initialPage = _router.activeIndex > previousIndex ? _router.activeIndex - 1 : _router.activeIndex + 1;
    _disposeInactiveChildren();
    setState(() {
      _warpUnderwayCount += 1;
      _children = List<Widget>.of(_children, growable: false);
      final Widget temp = _children[initialPage];
      _children[initialPage] = _children[previousIndex];
      _children[previousIndex] = temp;
    });
    _controller.jumpToPage(initialPage);

    if (animatePageTransition) {
      await _controller.animateToPage(_router.activeIndex, duration: duration, curve: Curves.ease);
    } else {
      _controller.jumpToPage(_router.activeIndex);
    }
    if (!mounted) return Future<void>.value();
    setState(() {
      _warpUnderwayCount -= 1;
    });
  }

  // Called when the PageView scrolls
  bool _handleScrollNotification(ScrollNotification notification) {
    if (_warpUnderwayCount > 0) return false;
    if (notification.depth != 0) return false;
    _warpUnderwayCount += 1;

    if (notification is ScrollUpdateNotification) {
      final currentPage = _controller.page!.round();
      _router.setActiveIndex(currentPage);
      final deltaDx = notification.dragDetails?.delta.dx;
      if (deltaDx != null) {
        if (deltaDx > 0 && currentPage > 0) {
          preload(currentPage - 1);
        } else if (deltaDx < 0 && currentPage < _children.length) {
          preload(currentPage + 1);
        }
      }
    }
    _warpUnderwayCount -= 1;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: EagerPageView(
        scrollDirection: widget.scrollDirection,
        dragStartBehavior: widget.dragStartBehavior,
        cacheExtent: _children.length,
        controller: _controller,
        physics: widget.physics == null
            ? const PageScrollPhysics().applyTo(const ClampingScrollPhysics())
            : const PageScrollPhysics().applyTo(widget.physics),
        // children: _children,
        children: _children,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<PageController>('controller', _controller));
    properties.add(DiagnosticsProperty<TabsRouter>('router', _router));
    properties.add(IntProperty('activeIndex', _router.activeIndex));
    properties.add(IntProperty('previousIndex', _router.previousIndex));
    properties.add(IntProperty('childrenCount', _children.length));
  }
}
