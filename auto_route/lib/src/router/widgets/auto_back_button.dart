import 'package:auto_route/src/router/controller/controller_scope.dart';
import 'package:auto_route/src/router/controller/pageless_routes_observer.dart';
import 'package:flutter/material.dart';

import '../../../auto_route.dart';

class AutoBackButton extends StatefulWidget {
  final Color? color;
  final bool showIfParentCanPop;

  const AutoBackButton({
    Key? key,
    this.color,
    this.showIfParentCanPop = true,
  }) : super(key: key);

  @override
  State<AutoBackButton> createState() => _AutoBackButtonState();
}

class _AutoBackButtonState extends State<AutoBackButton> {
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
      return BackButton(
        color: widget.color,
        onPressed: scope.controller.popTop,
      );
    }
    return const SizedBox.shrink();
  }

  bool _canPopSelfOrChildren(RoutingController controller) {
    if (controller.parent() != null && widget.showIfParentCanPop) {
      return controller.canPopSelfOrChildren ||
          _canPopSelfOrChildren(controller.parent()!);
    }
    return controller.canPopSelfOrChildren;
  }

  void _handleRebuild() {
    setState(() {});
  }
}
