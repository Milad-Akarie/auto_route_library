import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
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

/// Signature function to provide nullable leading widget
/// based on the current router state
typedef NullableWidgetBuilder = Widget Function(BuildContext context, Widget? leading);

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
/// and Page2 has an AutoLeadingButton(), clicking
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

  final NullableWidgetBuilder? _nullableBuilder;

  /// Default constructor
  const AutoLeadingButton({
    super.key,
    this.color,
    bool? showIfParentCanPop,
    this.showIfChildCanPop = true,
    this.ignorePagelessRoutes = false,
    this.builder,
  })  : assert(color == null || builder == null),
        _nullableBuilder = null,
        _showIfParentCanPop = showIfParentCanPop ?? true;

  /// builds a nullable leading widget based on the current router state
  ///
  /// This meant to be used above the AppBar so the [leading] property
  /// is passed to the AppBar's leading property,
  ///
  /// e.g
  /// ```dart
  ///
  ///    AutoLeadingButton.builder(
  ///    builder: (context, leading) {
  ///     return AppBar(
  ///            leading: leading,
  ///            title: Text('My Page'),
  ///            ),
  ///        ..
  ///         ),
  ///     ),
  const AutoLeadingButton.builder({
    super.key,
    this.color,
    bool? showIfParentCanPop,
    this.showIfChildCanPop = true,
    this.ignorePagelessRoutes = false,
    required NullableWidgetBuilder builder,
  })  : _nullableBuilder = builder,
        builder = null,
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
    Widget? leading;
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
      leading = useCloseButton
          ? CloseButton(
              key: const ValueKey(LeadingType.close),
              color: widget.color,
              onPressed: scope.controller.maybePopTop,
            )
          : BackButton(
              key: const ValueKey(LeadingType.back),
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
      leading = IconButton(
        key: const ValueKey(LeadingType.drawer),
        icon: const Icon(Icons.menu),
        iconSize: Theme.of(context).iconTheme.size ?? 24,
        onPressed: _handleDrawerButton,
        tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      );
    }

    if (widget.builder != null) {
      return widget.builder!(context, LeadingType.noLeading, null);
    }
    if (widget._nullableBuilder != null) {
      return widget._nullableBuilder!(context, leading);
    }
    return leading ??
        const SizedBox.shrink(
          key: ValueKey(LeadingType.noLeading),
        );
  }

  void _handleDrawerButton() {
    Scaffold.of(context).openDrawer();
  }

  void _handleRebuild() {
    setState(() {});
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AutoLeadingButtonBuilder?>('builder', widget.builder));
    properties.add(DiagnosticsProperty<NullableWidgetBuilder?>('nullableBuilder', widget._nullableBuilder));
    properties.add(DiagnosticsProperty<bool>('showIfChildCanPop', widget.showIfChildCanPop));
    properties.add(DiagnosticsProperty<bool>('ignorePagelessRoutes', widget.ignorePagelessRoutes));
    properties.add(DiagnosticsProperty<bool>('showIfParentCanPop', widget._showIfParentCanPop));
    properties.add(DiagnosticsProperty<Color?>('color', widget.color));
    properties.add(DiagnosticsProperty<RouterScope>('scope', RouterScope.of(context)));
    properties.add(DiagnosticsProperty<PagelessRoutesObserver>('pagelessRoutesObserver', _pagelessRoutesObserver));
  }
}
