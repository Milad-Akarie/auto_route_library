/// Most of the code here is taking from flutter's [TabView]

import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class AutoPageView extends StatefulWidget {
  const AutoPageView({
    Key? key,
    required this.controller,
    this.physics,
    required this.router,
    this.dragStartBehavior = DragStartBehavior.start,
  }) : super(key: key);

  final PageController controller;

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

class AutoPageViewState extends State<AutoPageView> {
  late final PageController _controller = widget.controller;
  late final TabsRouter _router = widget.router;
  late List<Widget> _children;
  int _warpUnderwayCount = 0;

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
    if (_router.activeIndex != _controller.page!.round()) {
      _warpToCurrentIndex();
    }
  }

  void _updateChildren() {
    final stack = widget.router.stack;
    _children = List.generate(
      stack.length,
      (index) => KeepAliveTab(
        key: ValueKey(index),
        page: stack[index],
      ),
    );
  }

  Future<void> _warpToCurrentIndex() async {
    if (!mounted) return Future<void>.value();

    const Duration duration = Duration(milliseconds: 300);

    if (duration == Duration.zero) {
      _controller.jumpToPage(_router.activeIndex);
      return Future<void>.value();
    }
    final int previousIndex = _router.previousIndex ?? 0;
    if ((_router.activeIndex - previousIndex).abs() == 1) {
      _warpUnderwayCount += 1;
      await _controller.animateToPage(_router.activeIndex,
          duration: duration, curve: Curves.ease);
      _warpUnderwayCount -= 1;
      return Future<void>.value();
    }
    assert((_router.activeIndex - previousIndex).abs() > 1);
    final int initialPage = _router.activeIndex > previousIndex
        ? _router.activeIndex - 1
        : _router.activeIndex + 1;

    setState(() {
      _warpUnderwayCount += 1;
      _children = List<Widget>.of(_children, growable: false);
      final Widget temp = _children[initialPage];
      _children[initialPage] = _children[previousIndex];
      _children[previousIndex] = temp;
    });
    _controller.jumpToPage(initialPage);

    await _controller.animateToPage(_router.activeIndex,
        duration: duration, curve: Curves.ease);
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
      _router.setActiveIndex(_controller.page!.round());
    }
    _warpUnderwayCount -= 1;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: PageView(
        dragStartBehavior: widget.dragStartBehavior,
        controller: _controller,
        physics: widget.physics == null
            ? const PageScrollPhysics().applyTo(const ClampingScrollPhysics())
            : const PageScrollPhysics().applyTo(widget.physics),
        children: _children,
      ),
    );
  }
}
