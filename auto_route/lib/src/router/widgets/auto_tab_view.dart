// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/router/widgets/eager_page_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

/// The adjustments made to this code from `TabView` is to fix children not
/// updating in sync with TabRouter changes
/// and to set pageController.offset.round() to [TabController.index]
/// so page is set when the scroll pos is rounded to it
class AutoTabView extends StatefulWidget {
  /// Creates a page view with one child per tab.

  const new({
    required this.controller,
    required this.router,
    super.key,
    this.physics,
    this.lazyLoad = true,
    this.scrollDirection = Axis.horizontal,
    this.dragStartBehavior = DragStartBehavior.start,
  });

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

  /// Whether each tab's page is built only once the tab is first shown.
  ///
  /// Defaults to true. When false, every tab's page is built with the tabs,
  /// so a tab's state and inner router exist before its first visit, and
  /// observers hear of every tab through
  /// [AutoRouterObserver.didInitTabRoute] at once. A tab whose route doesn't
  /// `maintainState` is still dropped when another tab shows.
  final bool lazyLoad;

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
  int _scrollUnderwayCount = 0;
  // Keyed by tab, not index, so a tab moved by a routes change keeps its state.
  final _tabKeys = <LocalKey, GlobalKey<KeepAliveTabState>>{};
  // Tabs a drag loaded before they were opened; observers have not heard of them.
  final _draggedInTabs = <LocalKey>{};

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
  ///
  /// Returns true when this opens the tab for the first time, also when a
  /// drag already loaded it.
  bool preload(int index) {
    final draggedIn = _draggedInTabs.remove(_matchIdAt(index));
    final didPreload = _tabKeyAt(index)?.currentState?.preload() == true;
    if (didPreload && mounted) {
      setState(_updateChildren);
    }
    return didPreload || draggedIn;
  }

  // Loads the tab a drag is uncovering, without opening it. A guarded tab
  // loads only once its guards let it in.
  void _preloadDraggedIn(int index) {
    if (_isGuarded(index)) return;
    if (_tabKeyAt(index)?.currentState?.preload() != true) return;
    _draggedInTabs.add(_matchIdAt(index)!);
    _updateChildren();
  }

  // Whether the tab at [index] is not the active one and has guards, which
  // are asked once a drag to it ends rather than as it passes.
  bool _isGuarded(int index) {
    if (index == _router.activeIndex) return false;
    return _router.stack.elementAtOrNull(index)?.routeData.route.guards.isNotEmpty ?? false;
  }

  @override
  void didUpdateWidget(AutoTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.animation?.removeListener(_handleTabControllerAnimationTick);
      // Removed in didUpdateWidget and dispose.
      // ignore: always-remove-listener
      _controller.animation?.addListener(_handleTabControllerAnimationTick);
      _updateChildren();
      // Load the active tab, it may not have been opened yet.
      _tabKeyAt(_router.activeIndex)?.currentState?.preload();

      // The routes changed: show the new pages on the active one.
      _currentIndex = _controller.index;
      correctToPage(_pageController, _currentIndex!);
    }
  }

  void _onRouterUpdated() {
    _disposeInactiveChildren();
    if (mounted) {
      setState(_updateChildren);
    }
  }

  @override
  void dispose() {
    if (_controllerIsValid) {
      _controller.animation!.removeListener(_handleTabControllerAnimationTick);
    }
    _router.removeListener(_onRouterUpdated);
    _pageController.dispose();
    super.dispose();
  }

  LocalKey? _matchIdAt(int index) {
    final stack = _router.stack;
    if (index < 0) return null;
    return stack.elementAtOrNull(index)?.routeData.matchId;
  }

  GlobalKey<KeepAliveTabState>? _tabKeyAt(int index) => _tabKeys[_matchIdAt(index)];

  void _updateChildren() {
    final stack = _router.stack;
    final matchIds = {for (final page in stack) page.routeData.matchId};
    _tabKeys.removeWhere((matchId, _) => !matchIds.contains(matchId));
    _draggedInTabs.retainAll(matchIds);
    _children = List.generate(stack.length, (index) {
      final isActive = _router.activeIndex == index;
      // The page view keeps every tab laid out beside the active one; a screen
      // reader or the keyboard must not reach those.
      return ExcludeSemantics(
        excluding: !isActive,
        child: ExcludeFocus(
          excluding: !isActive,
          child: KeepAliveTab(
            key: _tabKeys.putIfAbsent(stack[index].routeData.matchId, GlobalKey.new),
            initiallyLoaded: isActive || !widget.lazyLoad,
            page: stack[index],
          ),
        ),
      );
    });
  }

  void _disposeInactiveChildren() {
    final stack = _router.stack;
    for (var i = 0; i < stack.length; i++) {
      if (i != _router.activeIndex) {
        _tabKeys[stack[i].routeData.matchId]?.currentState?.unloadIfRequired();
      }
    }
  }

  void _handleTabControllerAnimationTick() {
    if (_scrollUnderwayCount > 0 || !_controller.indexIsChanging) {
      return;
    } // This widget is driving the controller's animation.
    if (_controller.index != _currentIndex) {
      _currentIndex = _controller.index;
      unawaited(_warpToCurrentIndex());
    }
  }

  Future<void> _warpToCurrentIndex() async {
    if (!mounted || _pageController.page == _currentIndex!.toDouble()) {
      return;
    }
    _disposeInactiveChildren();
    final adjacentDestination = (_currentIndex! - _controller.previousIndex).abs() == 1;
    if (adjacentDestination) {
      await _warpToAdjacentTab(_controller.animationDuration);
    } else {
      await _warpToNonAdjacentTab(_controller.animationDuration);
    }

    if (mounted) {
      setState(_updateChildren);
    }
  }

  void _jumpToPage(int page) {
    _warpUnderwayCount += 1;
    _pageController.jumpToPage(page);
    _warpUnderwayCount -= 1;
  }

  Future<void> _animateToPage(int page, {required Duration duration, required Curve curve}) async {
    _warpUnderwayCount += 1;
    await _pageController.animateToPage(page, duration: duration, curve: curve);
    _warpUnderwayCount -= 1;
  }

  Future<void> _warpToAdjacentTab(Duration duration) async {
    if (duration == .zero) {
      _jumpToPage(_currentIndex!);
    } else {
      await _animateToPage(_currentIndex!, duration: duration, curve: Curves.ease);
    }
  }

  Future<void> _warpToNonAdjacentTab(Duration duration) async {
    final previousIndex = _controller.previousIndex;
    assert((_currentIndex! - previousIndex).abs() > 1, 'Only a jump of more than one tab warps.');

    // initialPage defines which page is shown when starting the animation.
    // This page is adjacent to the destination page.
    final initialPage = _currentIndex! > previousIndex ? _currentIndex! - 1 : _currentIndex! + 1;

    setState(() {
      // Needed for `RenderSliverMultiBoxAdaptor.move` and kept alive children.
      // For motivation, see https://github.com/flutter/flutter/pull/29188 and
      // https://github.com/flutter/flutter/issues/27010#issuecomment-486475152.
      _children = List.of(_children, growable: false);
      final temp = _children[initialPage];
      _children[initialPage] = _children[previousIndex];
      _children[previousIndex] = temp;
    });

    // Make a first jump to the adjacent page.
    _jumpToPage(initialPage);

    // Jump or animate to the destination page.
    if (duration == .zero) {
      _jumpToPage(_currentIndex!);
    } else {
      await _animateToPage(_currentIndex!, duration: duration, curve: Curves.ease);
    }
  }

  // Called when the PageView scrolls
  void _handleScrollNotification(ScrollNotification notification) {
    if (_warpUnderwayCount > 0 || _scrollUnderwayCount > 0) {
      return;
    }

    if (notification.depth != 0) return;

    _scrollUnderwayCount += 1;
    if (notification is ScrollUpdateNotification && !_controller.indexIsChanging) {
      if ((_pageController.page! - _controller.index).abs() > 1.0) {
        _controller.index = _pageController.page!.round();
        _currentIndex = _controller.index;
      }
      final currentPage = _pageController.page!.round();
      if (!_isGuarded(currentPage)) {
        _controller.index = currentPage;
      }
      _controller.offset = (_pageController.page! - _controller.index).clamp(-1.0, 1.0);
      final deltaDx = notification.dragDetails?.delta.dx;
      if (deltaDx != null) {
        if (deltaDx > 0 && currentPage > 0) {
          _preloadDraggedIn(currentPage - 1);
        } else if (deltaDx < 0 && currentPage < _children.length) {
          _preloadDraggedIn(currentPage + 1);
        }
      }
    } else if (notification is ScrollEndNotification) {
      final currentPage = _pageController.page!.round();
      if (_isGuarded(currentPage)) {
        _router.setActiveIndex(currentPage);
        // Until its guards let the tab in, the active one shows. The scroll
        // that ended settles first.
        if (_router.activeIndex != currentPage) {
          _controller.offset = 0;
          scheduleMicrotask(() {
            if (mounted) {
              unawaited(
                _animateToPage(_router.activeIndex, duration: _controller.animationDuration, curve: Curves.ease),
              );
            }
          });
          _scrollUnderwayCount -= 1;
          return;
        }
      }
      _controller.index = currentPage;
      _currentIndex = _controller.index;
      if (!_controller.indexIsChanging) {
        _controller.offset = (_pageController.page! - _controller.index).clamp(-1.0, 1.0);
      }
    }
    _scrollUnderwayCount -= 1;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _handleScrollNotification(notification);
        // The notification keeps bubbling up.
        return false;
      },
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
    properties
      ..add(DiagnosticsProperty<TabController>('controller', _controller))
      ..add(DiagnosticsProperty<TabsRouter>('router', _router))
      ..add(IntProperty('activeIndex', _router.activeIndex))
      ..add(IntProperty('previousIndex', _router.previousIndex))
      ..add(IntProperty('childrenCount', _children.length));
  }
}
