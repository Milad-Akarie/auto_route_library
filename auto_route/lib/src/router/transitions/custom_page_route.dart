import 'package:flutter/material.dart';

class AutoPageRouteBuilder<T> extends PageRoute<T> {
  AutoPageRouteBuilder({
    this.transitionBuilder,
    this.transitionDuration = const Duration(milliseconds: 300),
    required this.child,
    bool fullscreenDialog = false,
  }) : super(fullscreenDialog: fullscreenDialog);

  final RouteTransitionsBuilder? transitionBuilder;
  final Widget child;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return child;
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    if (transitionBuilder != null) {
      return transitionBuilder!(
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }
    final theme = Theme.of(context);
    return theme.pageTransitionsTheme.buildTransitions(
      this,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }

  @override
  bool get maintainState => true;

  @override
  final Duration transitionDuration;
}
