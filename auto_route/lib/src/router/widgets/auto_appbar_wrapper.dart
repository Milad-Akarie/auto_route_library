import 'package:auto_route/src/router/controller/controller_scope.dart';
import 'package:flutter/material.dart';

import '../../../auto_route.dart';

class AutoAppBarWrapper extends StatelessWidget implements PreferredSizeWidget {
  final OnNavigationChangeBuilder builder;
  const AutoAppBarWrapper({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NavigationChangeBuilder(
      scope: RoutingControllerScope.of(context)!.controller,
      builder: builder,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class AutoBackButton extends StatelessWidget {
  final Color? color;
  const AutoBackButton({Key? key, this.color}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final scope = RoutingControllerScope.of(context);
    assert(scope != null);
    if (scope!.controller.topMost.canPopPage) {
      return BackButton(
        color: color,
        onPressed: scope.controller.topMost.pop,
      );
    }
    return const SizedBox.shrink();
  }
}
