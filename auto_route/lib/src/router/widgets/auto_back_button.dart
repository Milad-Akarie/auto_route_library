import 'package:auto_route/src/router/controller/controller_scope.dart';
import 'package:flutter/material.dart';

import '../../../auto_route.dart';

class AutoBackButton extends StatelessWidget {
  final Color? color;
  final bool showIfParentCanPop;
  const AutoBackButton({
    Key? key,
    this.color,
    this.showIfParentCanPop = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scope = AutoRouter.of(context, watch: true);
    if (scope.canPopSelfOrChildren ||
        (showIfParentCanPop && scope.parent()?.canPopSelfOrChildren == true)) {
      return BackButton(
        color: color,
        onPressed: scope.popTop,
      );
    }
    return const SizedBox.shrink();
  }
}
