import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/router/widgets/eager_page_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

/// Most of the code here is taking from flutter's `TabView`
class AutoPageView extends StatefulWidget {
  /// Default constructor
  const new({
    super.key,
    required this.animatePageTransition,
    this.duration = const Duration(milliseconds: 300),
    required this.controller,
    this.physics,
    required this.router,
    this.lazyLoad = true,
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

  /// Whether each tab's page is built only once the tab is first shown.
  ///
  /// Defaults to true. When false, every tab's page is built with the tabs,
  /// so a tab's state and inner router exist before its first visit, and
  /// observers hear of every tab through
  /// [AutoRouterObserver.didInitTabRoute] at once. A tab whose route doesn't
  /// `maintainState` is still dropped when another tab shows.
  final bool lazyLoad;

  @override
  State<AutoPageView> createState() => AutoPageViewState();
}

/// State implementation of [AutoPageView]
class AutoPageViewState extends State<AutoPageView> {
  PageController get _controller => widget.controller;
  // The router belongs to the parent widget, not to this state.
  // ignore: dispose-fields
  late final TabsRouter _router = widget.router;
  late List<Widget> _children;
  int _warpUnderwayCount = 0;
  int _scrollUnderwayCount = 0;
  // Keyed by tab, not index, so a tab moved by a routes change keeps its state.
  final _tabKeys = <LocalKey, GlobalKey<KeepAliveTabState>>{};
  // The tabs [_children] were built for, to tell when the routes change.
  var _matchIds = <LocalKey>[];
  // Tabs a drag loaded before they were opened; observers have not heard of them.
  final _draggedInTabs = <LocalKey>{};

  @override
  void initState() {
    super.initState();
    _updateChildren();
    _router.addListener(_routerListener);
  }

  @override
  void didUpdateWidget(AutoPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(_router.stack.map((page) => page.routeData.matchId).toList(), _matchIds)) {
      // The routes changed: show the new pages on the active one, and load
      // it, it may not have been opened yet.
      _updateChildren();
      _tabKeyAt(_router.activeIndex)?.currentState?.preload();
      correctToPage(_controller, _router.activeIndex);
    }
  }

  @override
  void dispose() {
    _router.removeListener(_routerListener);
    super.dispose();
  }

  void _routerListener() {
    if (mounted) {
      // Rebuilds so only the new active tab is reachable.
      setState(_updateChildren);
    }
    _disposeInactiveChildren();
    if (_router.activeIndex != _controller.page!.round()) {
      unawaited(_warpToCurrentIndex());
    }
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
    if (_router.stack.elementAtOrNull(index)?.routeData.route.guards.isNotEmpty ?? false) return;
    if (_tabKeyAt(index)?.currentState?.preload() != true) return;
    _draggedInTabs.add(_matchIdAt(index)!);
    if (mounted) {
      setState(_updateChildren);
    }
  }

  LocalKey? _matchIdAt(int index) {
    final stack = _router.stack;
    if (index < 0) return null;
    return stack.elementAtOrNull(index)?.routeData.matchId;
  }

  GlobalKey<KeepAliveTabState>? _tabKeyAt(int index) => _tabKeys[_matchIdAt(index)];

  void _updateChildren() {
    final stack = widget.router.stack;
    _matchIds = [for (final page in stack) page.routeData.matchId];
    _tabKeys.removeWhere((matchId, _) => !_matchIds.contains(matchId));
    _draggedInTabs.retainAll(_matchIds);
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

  void _jumpToPage(int page) {
    _warpUnderwayCount += 1;
    _controller.jumpToPage(page);
    _warpUnderwayCount -= 1;
  }

  // A zero duration jumps: animateToPage asserts a duration above zero.
  bool get _animates => widget.animatePageTransition && widget.duration > .zero;

  Future<void> _animateToPage(int page) async {
    _warpUnderwayCount += 1;
    await _controller.animateToPage(page, duration: widget.duration, curve: Curves.ease);
    _warpUnderwayCount -= 1;
  }

  Future<void> _warpToAdjacentTab() async {
    if (_animates) {
      await _animateToPage(_router.activeIndex);
    } else {
      _jumpToPage(_router.activeIndex);
    }

    return Future.value();
  }

  Future<void> _warpToNonAdjacentTab(int previousIndex) async {
    assert((_router.activeIndex - previousIndex).abs() > 1, 'Only a jump of more than one page warps.');
    final initialPage = _router.activeIndex > previousIndex ? _router.activeIndex - 1 : _router.activeIndex + 1;

    setState(() {
      _children = List.of(_children, growable: false);
      final temp = _children[initialPage];
      _children[initialPage] = _children[previousIndex];
      _children[previousIndex] = temp;
    });
    _jumpToPage(initialPage);

    if (_animates) {
      await _animateToPage(_router.activeIndex);
    } else {
      _jumpToPage(_router.activeIndex);
    }
  }

  Future<void> _warpToCurrentIndex() async {
    if (!mounted) return Future.value();

    _disposeInactiveChildren();
    // From the page on screen: it's the tab before the active one, or the
    // tab a swipe reached when its guards kept it out.
    final previousIndex = _controller.page!.round();

    final adjacentDestination = (_router.activeIndex - previousIndex).abs() == 1;
    if (adjacentDestination) {
      await _warpToAdjacentTab();
    } else {
      await _warpToNonAdjacentTab(previousIndex);
    }
    if (mounted) {
      setState(_updateChildren);
    }
  }

  // Called when the PageView scrolls
  // Returns false so the notification keeps bubbling up.
  // ignore: function-always-returns-same-value
  bool _handleScrollNotification(ScrollNotification notification) {
    if (_warpUnderwayCount > 0 || _scrollUnderwayCount > 0) {
      return false;
    }
    if (notification.depth != 0) return false;
    _scrollUnderwayCount += 1;
    if (notification is ScrollUpdateNotification) {
      final currentPage = _controller.page!.round();
      _router.setActiveIndex(currentPage);
      final deltaDx = notification.dragDetails?.delta.dx;
      if (deltaDx != null) {
        if (deltaDx > 0 && currentPage > 0) {
          _preloadDraggedIn(currentPage - 1);
        } else if (deltaDx < 0 && currentPage < _children.length) {
          _preloadDraggedIn(currentPage + 1);
        }
      }
    }
    _scrollUnderwayCount -= 1;
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
        children: _children,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<PageController>('controller', _controller))
      ..add(DiagnosticsProperty<TabsRouter>('router', _router))
      ..add(IntProperty('activeIndex', _router.activeIndex))
      ..add(IntProperty('previousIndex', _router.previousIndex))
      ..add(IntProperty('childrenCount', _children.length));
  }
}
