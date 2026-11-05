import 'package:auto_route/src/router/transitions/flutter_material_theme.dart';
import 'package:material_ui/material_ui.dart';

/// A default implementation of [PageRoute]
/// used by `StackRouter.pushWidget`
class AutoPageRouteBuilder<T> extends PageRoute<T> {
  /// Default constructor
  new({
    required this._child,
    required this._transitionBuilder,
    required this.transitionDuration,
    required this.opaque,
    super.fullscreenDialog,
  });

  /// See `PageRouteBuilder.transitionBuilder`
  final RouteTransitionsBuilder? _transitionBuilder;

  /// The page to be displayed
  final Widget _child;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return _child;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (_transitionBuilder != null) {
      return _transitionBuilder(context, animation, secondaryAnimation, child);
    }
    final flutterTheme = flutterMaterialThemeOf(context);
    if (flutterTheme != null) {
      return flutterTheme.pageTransitionsTheme.buildTransitions(this, context, animation, secondaryAnimation, child);
    }
    final theme = Theme.of(context);
    return theme.pageTransitionsTheme.buildTransitions(this, context, animation, secondaryAnimation, child);
  }

  @override
  bool get maintainState => true;

  @override
  final Duration transitionDuration;

  @override
  final bool opaque;
}
