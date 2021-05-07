import 'package:auto_route/src/router/controller/controller_scope.dart';
import 'package:flutter/material.dart';

import '../../../auto_route.dart';

class AutoBackButton extends StatefulWidget {
  final Color? color;
  const AutoBackButton({Key? key, this.color}) : super(key: key);

  @override
  _AutoBackButtonState createState() => _AutoBackButtonState();
}

class _AutoBackButtonState extends State<AutoBackButton> {
  @override
  Widget build(BuildContext context) {
    final scope = RouterScope.of(context);
    if (scope.controller.canPopSelfOrChildren) {
      return BackButton(
        color: widget.color,
        onPressed: scope.controller.popTop,
      );
    }
    return const SizedBox.shrink();
  }
}
