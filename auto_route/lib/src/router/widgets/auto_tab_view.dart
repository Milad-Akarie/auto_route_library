// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/router/widgets/eager_page_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// The adjustments made to this code from [TabView] is to fix children not
/// updating in sync with TabRouter changes
/// and to set pageController.offset.round() to [TabController.index]
/// so page is set when the scroll pos is rounded to it
class AutoTabView extends StatefulWidget {
  /// Creates a page view with one child per tab.

  const AutoTabView({
    super.key,
    required this.animatePageTransition,
    required this.controller,
    this.physics,
    required this.router,
    this.scrollDirection = Axis.horizontal,
    this.dragStartBehavior = DragStartBehavior.start,
  });

  /// Whether to use [TabController.animateToPage] or [TabController.jumpToPage]
  final bool animatePageTransition;

  /// The scroll direction of the [PageView]
  /// see [PageView.scrollDirection]
  final Axis scrollDirection;

  /// The page controller used by [PageView]
  /// see [PageView.controller]
  final TabController controller;

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
  State<AutoTabView> createState() => AutoTabViewState();
}

/// State implementation of [AutoTabView]
class AutoTabViewState extends State<AutoTabView> {
  TabController get _controller => widget.controller;
  late PageController _pageController;
  late List<Widget> _children;
  int? _currentIndex;
  int _warpUnderwayCount = 0;
  final _tabKeys = <int, GlobalKey<KeepAliveTabState>>{};

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
    _router.addListener(_onRouterUpdated);
    _pageController = PageController(initialPage: _router.activeIndex);
  }

  /// Preload the page at [index]
  bool preload(int index) {
    final didPreload = _tabKeys[index]?.currentState?.preload() == true;
    if (didPreload) {
      _updateChildren();
    }
    return didPreload;
  }

  @override
  void didUpdateWidget(AutoTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.animation?.removeListener(_handleTabControllerAnimationTick);
      _controller.animation?.addListener(_handleTabControllerAnimationTick);
      _updateChildren();

      _currentIndex = _controller.index;
      _pageController.jumpToPage(_currentIndex!);
    }
  }

  void _onRouterUpdated() {
    _disposeInactiveChildren();
    _updateChildren();
  }

  @override
  void dispose() {
    if (_controllerIsValid) {
      _controller.animation!.removeListener(_handleTabControllerAnimationTick);
    }
    _router.removeListener(_onRouterUpdated);
    super.dispose();
  }

  void _updateChildren() {
    final stack = _router.stack;
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
    final bool animatePageTransition = widget.animatePageTransition;

    final int previousIndex = _controller.previousIndex;

    if ((_currentIndex! - previousIndex).abs() == 1) {
      _warpUnderwayCount += 1;
      if (animatePageTransition) {
        await _pageController.animateToPage(_currentIndex!, duration: duration, curve: Curves.ease);
      } else {
        _pageController.jumpToPage(_currentIndex!);
      }
      _warpUnderwayCount -= 1;
      return Future<void>.value();
    }

    assert((_currentIndex! - previousIndex).abs() > 1);
    final int initialPage = _currentIndex! > previousIndex ? _currentIndex! - 1 : _currentIndex! + 1;
    setState(() {
      _warpUnderwayCount += 1;
      _children = List<Widget>.of(_children, growable: false);
      final Widget temp = _children[initialPage];
      _children[initialPage] = _children[previousIndex];
      _children[previousIndex] = temp;
    });
    _pageController.jumpToPage(initialPage);

    if (animatePageTransition) {
      await _pageController.animateToPage(_currentIndex!, duration: duration, curve: Curves.ease);
    } else {
      _pageController.jumpToPage(_currentIndex!);
    }
    if (!mounted) return Future<void>.value();
    setState(() {
      _warpUnderwayCount -= 1;
    });
  }

  // Called when the PageView scrolls
  bool _handleScrollNotification(ScrollNotification notification) {
    // if (notification is ScrollEndNotification) {
    //     print(widget.controller.indexIsChanging);
    //   _disposeInactiveChildren();
    // }
    if (_warpUnderwayCount > 0) return false;

    if (notification.depth != 0) return false;

    _warpUnderwayCount += 1;
    if (notification is ScrollUpdateNotification && !_controller.indexIsChanging) {
      if ((_pageController.page! - _controller.index).abs() > 1.0) {
        _controller.index = _pageController.page!.round();
        _currentIndex = _controller.index;
      }
      final currentPage = _pageController.page!.round();
      _controller.index = currentPage;
      _controller.offset = (_pageController.page! - _controller.index).clamp(-1.0, 1.0);
      final deltaDx = notification.dragDetails?.delta.dx;
      if (deltaDx != null) {
        if (deltaDx > 0 && currentPage > 0) {
          preload(currentPage - 1);
        } else if (deltaDx < 0 && currentPage < _children.length) {
          preload(currentPage + 1);
        }
      }
    } else if (notification is ScrollEndNotification) {
      _controller.index = _pageController.page!.round();
      _currentIndex = _controller.index;
      if (!_controller.indexIsChanging) {
        _controller.offset = (_pageController.page! - _controller.index).clamp(-1.0, 1.0);
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
        cacheExtent: _children.length,
        scrollDirection: widget.scrollDirection,
        dragStartBehavior: widget.dragStartBehavior,
        controller: _pageController,
        physics: widget.physics == null
            ? const PageScrollPhysics().applyTo(const ClampingScrollPhysics())
            : const PageScrollPhysics().applyTo(widget.physics),
        children: _children,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<TabController>('controller', _controller));
    properties.add(DiagnosticsProperty<TabsRouter>('router', _router));
    properties.add(IntProperty('activeIndex', _router.activeIndex));
    properties.add(IntProperty('previousIndex', _router.previousIndex));
    properties.add(IntProperty('childrenCount', _children.length));
  }
}
