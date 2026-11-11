// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Copied from Flutter: the code stays as Flutter wrote it, so the two can
// still be compared line by line.

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart'
    show
        Axis,
        AxisDirection,
        BuildContext,
        Clip,
        Directionality,
        NotificationListener,
        PageController,
        PageMetrics,
        PageScrollPhysics,
        ScrollBehavior,
        ScrollConfiguration,
        ScrollNotification,
        ScrollPhysics,
        ScrollUpdateNotification,
        Scrollable,
        Scrollbar,
        SliverChildDelegate,
        SliverChildListDelegate,
        SliverFillViewport,
        State,
        StatefulWidget,
        Viewport,
        Widget,
        debugCheckHasDirectionality;

/// This is a copy of the `PageView` widget from Flutter, with the following
/// changes:
/// - it allows for custom cacheExtent to be set
/// - it does not allow for setting allowImplicitScrolling because it is always
/// - it requires a [PageController] to be passed in

class _ForceImplicitScrollPhysics extends ScrollPhysics {
  const new({required this.allowImplicitScrolling, super.parent});

  @override
  _ForceImplicitScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _ForceImplicitScrollPhysics(
      allowImplicitScrolling: allowImplicitScrolling,
      parent: buildParent(ancestor),
    );
  }

  @override
  final bool allowImplicitScrolling;
}

const PageScrollPhysics _kPagePhysics = PageScrollPhysics();

/// Puts [controller] on [page] for the next layout, without animating or
/// sending scroll notifications.
///
/// For when the pages change: a jump before the new pages are laid out
/// would be measured against the old ones.
void correctToPage(PageController controller, int page) {
  if (!controller.hasClients) return;
  final position = controller.position;
  if (!position.hasViewportDimension) return;
  position.correctPixels(
    page * position.viewportDimension * controller.viewportFraction,
  );
}

/// A scrollable list that works page by page.
///
/// Each child of a page view is forced to be the same size as the viewport.
///
/// You can use a [PageController] to control which page is visible in the view.
/// In addition to being able to control the pixel offset of the content inside
/// the [EagerPageView], a [PageController] also lets you control the offset in
/// terms of pages, which are increments of the viewport size.
///
/// The [PageController] can also be used to control the
/// [PageController.initialPage], which determines which page is shown when the
/// [EagerPageView] is first constructed, and the
/// [PageController.viewportFraction], which determines the size of the pages as
/// a fraction of the viewport size.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=J1gE9xvph-A}
///
/// {@tool dartpad} Here is an example of [EagerPageView]. It creates a centered
/// `Text` in each of the three pages which scroll horizontally.
///
/// ** See code in examples/api/lib/widgets/page_view/page_view.0.dart **
/// {@end-tool}
///
/// ## Persisting the scroll position during a session
///
/// Scroll views attempt to persist their scroll position using `PageStorage`.
/// For a [EagerPageView], this can be disabled by setting
/// [PageController.keepPage] to false on the [_controller]. If it is enabled,
/// using a `PageStorageKey` for the [key] of this widget is recommended to help
/// disambiguate different scroll views from each other.
///
/// See also:
///
/// * [PageController], which controls which page is visible in the view. *
/// `SingleChildScrollView`, when you need to make a single child scrollable. *
/// `ListView`, for a scrollable list of boxes. * `GridView`, for a scrollable
/// grid of boxes. * [ScrollNotification] and [NotificationListener], which can
/// be used to watch
///    the scroll position without using a `ScrollController`.
class EagerPageView extends StatefulWidget {
  /// Creates a scrollable list that works page by page from an explicit [List]
  /// of widgets.
  ///
  /// This constructor is appropriate for page views with a small number of
  /// children because constructing the [List] requires doing work for every
  /// child that could possibly be displayed in the page view, instead of just
  /// those children that are actually visible.
  ///
  /// Like other widgets in the framework, this widget expects that the
  /// [children] list will not be mutated after it has been passed in here. See
  /// the documentation at [SliverChildListDelegate.children] for more details.
  ///

  new({
    required this._controller,
    required this._cacheExtent,
    required this._scrollDirection,
    required this._physics,
    required List<Widget> children,
    required this._dragStartBehavior,
    super.key,
    this._reverse = false,
    this._pageSnapping = true,
    this._onPageChanged,
    this._restorationId,
    this._clipBehavior = Clip.hardEdge,
    this._scrollBehavior,
    this._padEnds = true,
  }) : _childrenDelegate = SliverChildListDelegate(children);

  /// {@macro flutter.widgets.scrollable.restorationId}
  final String? _restorationId;

  /// The [Axis] along which the scroll view's offset increases with each page.
  ///
  /// For the direction in which active scrolling may be occurring, see
  /// [ScrollDirection].
  ///
  /// Defaults to [Axis.horizontal].
  final Axis _scrollDirection;

  /// Whether the page view scrolls in the reading direction.
  ///
  /// For example, if the reading direction is left-to-right and
  /// [_scrollDirection] is [Axis.horizontal], then the page view scrolls from
  /// left to right when [_reverse] is false and from right to left when
  /// [_reverse] is true.
  ///
  /// Similarly, if [_scrollDirection] is [Axis.vertical], then the page view
  /// scrolls from top to bottom when [_reverse] is false and from bottom to top
  /// when [_reverse] is true.
  ///
  /// Defaults to false.
  final bool _reverse;

  /// An object that can be used to control the position to which this page
  /// view is scrolled.
  final PageController _controller;

  /// How the page view should respond to user input.
  ///
  /// For example, determines how the page view continues to animate after the
  /// user stops dragging the page view.
  ///
  /// The physics are modified to snap to page boundaries using
  /// [PageScrollPhysics] prior to being used.
  ///
  /// If an explicit [ScrollBehavior] is provided to [_scrollBehavior], the
  /// [ScrollPhysics] provided by that behavior will take precedence after
  /// [_physics].
  ///
  /// Defaults to matching platform conventions.
  final ScrollPhysics? _physics;

  /// Set to false to disable page snapping, useful for custom scroll behavior.
  ///
  /// If the [_padEnds] is false and [PageController.viewportFraction] < 1.0,
  /// the page will snap to the beginning of the viewport; otherwise, the page
  /// will snap to the center of the viewport.
  final bool _pageSnapping;

  /// Called whenever the page in the center of the viewport changes.
  final ValueChanged<int>? _onPageChanged;

  /// A delegate that provides the children for the [EagerPageView].
  ///
  /// The `PageView.custom` constructor lets you specify this delegate
  /// explicitly. The [EagerPageView] and `PageView.builder` constructors create
  /// a [_childrenDelegate] that wraps the given [List] and
  /// `IndexedWidgetBuilder`, respectively.
  final SliverChildDelegate _childrenDelegate;

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior _dragStartBehavior;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip _clipBehavior;

  /// The number of pages that should be eagerly rendered by the [EagerPageView]
  final int _cacheExtent;

  /// {@macro flutter.widgets.shadow.scrollBehavior}
  ///
  /// [ScrollBehavior]s also provide [ScrollPhysics]. If an explicit
  /// [ScrollPhysics] is provided in [_physics], it will take precedence,
  /// followed by [_scrollBehavior], and then the inherited ancestor
  /// [ScrollBehavior].
  ///
  /// The [ScrollBehavior] of the inherited [ScrollConfiguration] will be
  /// modified by default to not apply a [Scrollbar].
  final ScrollBehavior? _scrollBehavior;

  /// Whether to add padding to both ends of the list.
  ///
  /// If this is set to true and [PageController.viewportFraction] < 1.0,
  /// padding will be added such that the first and last child slivers will be
  /// in the center of the viewport when scrolled all the way to the start or
  /// end, respectively.
  ///
  /// If [PageController.viewportFraction] >= 1.0, this property has no effect.
  ///
  /// This property defaults to true.
  final bool _padEnds;

  @override
  State<EagerPageView> createState() => _EagerPageViewState();
}

class _EagerPageViewState extends State<EagerPageView> {
  int _lastReportedPage = 0;

  @override
  void initState() {
    super.initState();
    _lastReportedPage = widget._controller.initialPage;
  }

  AxisDirection _getDirection(BuildContext context) {
    switch (widget._scrollDirection) {
      case .horizontal:
        assert(
          debugCheckHasDirectionality(context),
          'A Directionality ancestor is required.',
        );
        final textDirection = Directionality.of(context);
        final axisDirection = textDirectionToAxisDirection(textDirection);
        return widget._reverse
            ? flipAxisDirection(axisDirection)
            : axisDirection;
      case .vertical:
        return widget._reverse ? .up : .down;
    }
  }

  @override
  Widget build(BuildContext context) {
    final axisDirection = _getDirection(context);
    final ScrollPhysics physics =
        const _ForceImplicitScrollPhysics(allowImplicitScrolling: false)
            .applyTo(
              widget._pageSnapping
                  ? _kPagePhysics.applyTo(
                      widget._physics ??
                          widget._scrollBehavior?.getScrollPhysics(context),
                    )
                  : (widget._physics ??
                        widget._scrollBehavior?.getScrollPhysics(context)),
            );

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.depth == 0 &&
            widget._onPageChanged != null &&
            notification is ScrollUpdateNotification) {
          final metrics = notification.metrics as PageMetrics;
          final currentPage = metrics.page!.round();
          if (currentPage != _lastReportedPage) {
            _lastReportedPage = currentPage;
            widget._onPageChanged!(currentPage);
          }
        }
        return false;
      },
      child: Scrollable(
        dragStartBehavior: widget._dragStartBehavior,
        axisDirection: axisDirection,
        controller: widget._controller,
        physics: physics,
        restorationId: widget._restorationId,
        scrollBehavior:
            widget._scrollBehavior ??
            ScrollConfiguration.of(context).copyWith(scrollbars: false),
        viewportBuilder: (context, position) {
          return Viewport(
            scrollCacheExtent: ScrollCacheExtent.viewport(
              widget._cacheExtent.toDouble(),
            ),
            axisDirection: axisDirection,
            offset: position,
            clipBehavior: widget._clipBehavior,
            slivers: [
              SliverFillViewport(
                viewportFraction: widget._controller.viewportFraction,
                delegate: widget._childrenDelegate,
                padEnds: widget._padEnds,
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description
      ..add(EnumProperty<Axis>('scrollDirection', widget._scrollDirection))
      ..add(FlagProperty('reverse', value: widget._reverse, ifTrue: 'reversed'))
      ..add(
        DiagnosticsProperty<PageController>(
          'controller',
          widget._controller,
          showName: false,
        ),
      )
      ..add(
        DiagnosticsProperty<ScrollPhysics>(
          'physics',
          widget._physics,
          showName: false,
        ),
      )
      ..add(
        FlagProperty(
          'pageSnapping',
          value: widget._pageSnapping,
          ifFalse: 'snapping disabled',
        ),
      )
      ..add(
        DiagnosticsProperty<int>(
          'cacheExtent',
          widget._cacheExtent,
          showName: false,
        ),
      );
  }
}
