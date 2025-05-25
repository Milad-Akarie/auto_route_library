import 'package:flutter/material.dart';

/// A default implementation of [PageRoute]
/// used by [StackRouter.pushWidget]
class AutoPageRouteBuilder<T> extends PageRoute<T> {
  /// Default constructor
  AutoPageRouteBuilder({
    this.transitionBuilder,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.opaque = true,
    required this.child,
    super.fullscreenDialog,
  });

  /// See [PageRouteBuilder.transitionBuilder]
  final RouteTransitionsBuilder? transitionBuilder;

  /// The page to be displayed
  final Widget child;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return child;
  }

  @override
  Widget buildTransitions(
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
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

  @override
  final bool opaque;
}
