import 'package:auto_route/src/router/controller/pageless_routes_observer.dart';
import 'package:flutter/material.dart';

import '../../../auto_route.dart';

enum LeadingType {
  back,
  close,
  drawer,
  noLeading;

  bool get isBack => this == back;

  bool get isClose => this == close;

  bool get isDrawer => this == drawer;

  bool get isNoLeading => this == noLeading;
}

typedef AutoLeadingButtonBuilder = Widget Function(
  BuildContext context,
  LeadingType leadingType,
  VoidCallback? action, // could be popTop, openDrawer or null
);

class AutoLeadingButton extends StatefulWidget {
  final Color? color;

  final bool showIfChildCanPop, ignorePagelessRoutes;
  final bool _showIfParentCanPop;
  final AutoLeadingButtonBuilder? builder;

  const AutoLeadingButton({
    Key? key,
    this.color,
    @Deprecated('Use showIfParentCanPop') bool? showBackIfParentCanPop,
    bool? showIfParentCanPop,
    this.showIfChildCanPop = true,
    this.ignorePagelessRoutes = false,
    this.builder,
  })  : assert(color == null || builder == null),
        _showIfParentCanPop =
            showIfParentCanPop ?? showBackIfParentCanPop ?? true,
        super(key: key);

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
          scope.controller.popTop,
        );
      }
      return useCloseButton
          ? CloseButton(
              color: widget.color,
              onPressed: scope.controller.popTop,
            )
          : BackButton(
              color: widget.color,
              onPressed: scope.controller.popTop,
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
