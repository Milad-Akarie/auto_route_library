import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/router/controller/pageless_routes_observer.dart';
import 'package:flutter/material.dart';

/// AppBar Leading button types
enum LeadingType {
  /// Whether to show a back button
  back,

  /// Whether to show a close button
  close,

  /// Whether to show a drawer toggle
  drawer,

  /// Whether to show no leading at all
  noLeading;

  /// Helper to check if this instance is [back]
  bool get isBack => this == back;

  /// Helper to check if this instance is [close]
  bool get isClose => this == close;

  /// Helper to check if this instance is [drawer]
  bool get isDrawer => this == drawer;

  /// Helper to check if this instance is [noLeading]
  bool get isNoLeading => this == noLeading;
}

/// Signature function to customize the
/// build of a leading button
typedef AutoLeadingButtonBuilder = Widget Function(
  BuildContext context,
  LeadingType leadingType,
  VoidCallback? action, // could be popTop, openDrawer or null
);

/// An AutoRoute replacement of appBar aut-leading-button
///
/// Unlike the default [BackButton] this button will always
/// the top-most route in the whole hierarchy not only current-stack
///
/// meant to be used with AppBar -> AppBar(leading: AutoLeadingButton())
///
/// e.g if we have such hierarchy
/// - page1
/// - page2
///     - sub-page1
///     - sub-page2
/// and Page2 has an  AutoLeadingButton(), clicking
/// it will pop sub-page2 then page2
///
class AutoLeadingButton extends StatefulWidget {
  /// The color of [BackButton] and [CloseButton]
  final Color? color;

  /// Whether to pop current stack and not care about
  /// child routes
  final bool showIfChildCanPop;

  /// Whether to ignore pageless routes when
  /// calculating top-most route
  ///
  /// What is a (PagelessRoute)?
  /// [Route] that does not correspond to a [Page] object is called a pageless
  /// route and is tied to the [Route] that _does_ correspond to a [Page] object
  /// that is below it in the history.
  final bool ignorePagelessRoutes;
  final bool _showIfParentCanPop;

  /// Clients can use this builder to customize
  /// the looks and feels of their leading buttons
  final AutoLeadingButtonBuilder? builder;

  /// Default constructor
  const AutoLeadingButton({
    super.key,
    this.color,
    bool? showIfParentCanPop,
    this.showIfChildCanPop = true,
    this.ignorePagelessRoutes = false,
    this.builder,
  })  : assert(color == null || builder == null),
        _showIfParentCanPop = showIfParentCanPop ?? true;

  @override
  State<AutoLeadingButton> createState() => _AutoLeadingButtonState();
}

class _AutoLeadingButtonState extends State<AutoLeadingButton> {
  late final PagelessRoutesObserver _pagelessRoutesObserver;

  @override
  void initState() {
    super.initState();
    _pagelessRoutesObserver = AutoRouter.of(context).pagelessRoutesObserver;
    _pagelessRoutesObserver.addListener(_handleRebuild);
  }

  @override
  void dispose() {
    super.dispose();
    _pagelessRoutesObserver.removeListener(_handleRebuild);
  }

  @override
  Widget build(BuildContext context) {
    final scope = RouterScope.of(context, watch: true);
    if (scope.controller.canPop(
      ignoreChildRoutes: !widget.showIfChildCanPop,
      ignoreParentRoutes: !widget._showIfParentCanPop,
      ignorePagelessRoutes: widget.ignorePagelessRoutes,
    )) {
      final topPage = scope.controller.topPage;
      final bool useCloseButton = topPage?.fullscreenDialog ?? false;
      if (widget.builder != null) {
        return widget.builder!(
          context,
          useCloseButton ? LeadingType.close : LeadingType.back,
          scope.controller.maybePopTop,
        );
      }
      return useCloseButton
          ? CloseButton(
              color: widget.color,
              onPressed: scope.controller.maybePopTop,
            )
          : BackButton(
              color: widget.color,
              onPressed: scope.controller.maybePopTop,
            );
    }
    final ScaffoldState? scaffold = Scaffold.maybeOf(context);
    if (scaffold?.hasDrawer == true) {
      if (widget.builder != null) {
        return widget.builder!(
          context,
          LeadingType.drawer,
          _handleDrawerButton,
        );
      }
      return IconButton(
        icon: const Icon(Icons.menu),
        iconSize: Theme.of(context).iconTheme.size ?? 24,
        onPressed: _handleDrawerButton,
        tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      );
    }

    if (widget.builder != null) {
      return widget.builder!(context, LeadingType.noLeading, null);
    }
    return const SizedBox.shrink();
  }

  void _handleDrawerButton() {
    Scaffold.of(context).openDrawer();
  }

  void _handleRebuild() {
    setState(() {});
  }
}
