import 'package:auto_route/src/router/controller/pageless_routes_observer.dart';
import 'package:flutter/material.dart';

import '../../../auto_route.dart';

class AutoLeadingButton extends StatefulWidget {
  final Color? color;
  final bool showBackIfParentCanPop;

  const AutoLeadingButton({
    Key? key,
    this.color,
    this.showBackIfParentCanPop = true,
  }) : super(key: key);

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
    if (_canPopSelfOrChildren(scope.controller)) {
      final bool useCloseButton =
          scope.controller.topPage?.fullscreenDialog ?? false;
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
      return IconButton(
        icon: const Icon(Icons.menu),
        iconSize: Theme.of(context).iconTheme.size ?? 24,
        onPressed: _handleDrawerButton,
        tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      );
    }
    return const SizedBox.shrink();
  }

  void _handleDrawerButton() {
    Scaffold.of(context).openDrawer();
  }

  bool _canPopSelfOrChildren(RoutingController controller) {
    if (controller.parent() != null && widget.showBackIfParentCanPop) {
      return controller.canPopSelfOrChildren ||
          _canPopSelfOrChildren(controller.parent()!);
    }
    return controller.canPopSelfOrChildren;
  }

  void _handleRebuild() {
    setState(() {});
  }
}
