// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The adjustments made to this code is to fix children not
/// updating in sync with TabRouter changes
/// and to set pageController.offset.round() to [TabController.index]
/// so page is set when the scroll pos is rounded to it

import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class AutoTabView extends StatefulWidget {
  /// Creates a page view with one child per tab.

  const AutoTabView({
    Key? key,
    required this.controller,
    this.physics,
    required this.router,
    this.dragStartBehavior = DragStartBehavior.start,
  }) : super(key: key);

  final TabController controller;

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
  State<AutoTabView> createState() => AutoTabViewState();
}

class AutoTabViewState extends State<AutoTabView> {
  TabController get _controller => widget.controller;
  late PageController _pageController;
  late List<Widget> _children;
  int? _currentIndex;
  int _warpUnderwayCount = 0;

  TabsRouter get _router => widget.router;

  // If the TabBarView is rebuilt with a new tab controller, the caller should
  // dispose the old one. In that case the old controller's animation will be
  // null and should not be accessed.
  bool get _controllerIsValid => _controller.animation != null;

  @override
  void initState() {
    super.initState();
    _updateChildren();
    _controller.animation!.addListener(_handleTabControllerAnimationTick);
    _router.addListener(_updateChildren);
    _pageController = PageController(initialPage: _router.activeIndex);
  }

  @override
  void didUpdateWidget(AutoTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _currentIndex = _controller.index;
      _pageController.jumpToPage(_currentIndex!);
    }
  }

  @override
  void dispose() {
    if (_controllerIsValid) {
      _controller.animation!.removeListener(_handleTabControllerAnimationTick);
    }
    _router.removeListener(_updateChildren);
    super.dispose();
  }

  void _updateChildren() {
    final stack = _router.stack;
    _children = List.generate(
      stack.length,
      (index) => KeepAliveTab(
        key: ValueKey(index),
        page: stack[index],
      ),
    );
  }

  void _handleTabControllerAnimationTick() {
    if (_warpUnderwayCount > 0 || !_controller.indexIsChanging) {
      return;
    } // This widget is driving the controller's animation.

    if (_controller.index != _currentIndex) {
      _currentIndex = _controller.index;
      _warpToCurrentIndex();
    }
  }

  Future<void> _warpToCurrentIndex() async {
    if (!mounted) return Future<void>.value();

    if (_pageController.page == _currentIndex!.toDouble()) {
      return Future<void>.value();
    }

    final Duration duration = _controller.animationDuration;

    if (duration == Duration.zero) {
      _pageController.jumpToPage(_currentIndex!);
      return Future<void>.value();
    }

    final int previousIndex = _controller.previousIndex;

    if ((_currentIndex! - previousIndex).abs() == 1) {
      _warpUnderwayCount += 1;
      await _pageController.animateToPage(_currentIndex!,
          duration: duration, curve: Curves.ease);
      _warpUnderwayCount -= 1;
      return Future<void>.value();
    }

    assert((_currentIndex! - previousIndex).abs() > 1);
    final int initialPage = _currentIndex! > previousIndex
        ? _currentIndex! - 1
        : _currentIndex! + 1;
    setState(() {
      _warpUnderwayCount += 1;
      _children = List<Widget>.of(_children, growable: false);
      final Widget temp = _children[initialPage];
      _children[initialPage] = _children[previousIndex];
      _children[previousIndex] = temp;
    });
    _pageController.jumpToPage(initialPage);

    await _pageController.animateToPage(_currentIndex!,
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
    if (notification is ScrollUpdateNotification &&
        !_controller.indexIsChanging) {
      if ((_pageController.page! - _controller.index).abs() > 1.0) {
        _controller.index = _pageController.page!.round();
        _currentIndex = _controller.index;
      }
      _controller.index = _pageController.page!.round();
      _controller.offset =
          (_pageController.page! - _controller.index).clamp(-1.0, 1.0);
    } else if (notification is ScrollEndNotification) {
      _controller.index = _pageController.page!.round();
      _currentIndex = _controller.index;
      if (!_controller.indexIsChanging) {
        _controller.offset =
            (_pageController.page! - _controller.index).clamp(-1.0, 1.0);
      }
    }
    _warpUnderwayCount -= 1;

    return false;
  }

  @override
  Widget build(BuildContext context) {
    assert(() {
      if (_controller.length != widget.router.pageCount) {
        throw FlutterError(
          "Controller's length property (${_controller.length}) does not match the "
          "number of tabs (${widget.router.pageCount}) present in TabsRouter pages count.",
        );
      }
      return true;
    }());
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: PageView(
        dragStartBehavior: widget.dragStartBehavior,
        controller: _pageController,
        physics: widget.physics == null
            ? const PageScrollPhysics().applyTo(const ClampingScrollPhysics())
            : const PageScrollPhysics().applyTo(widget.physics),
        children: _children,
      ),
    );
  }
}
