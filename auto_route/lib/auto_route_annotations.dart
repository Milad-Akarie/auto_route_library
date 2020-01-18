class AutoRouter {
  final bool generateNavigator;
  final bool generateRouteList;
  const AutoRouter({
    this.generateNavigator = true,
    this.generateRouteList = false,
  });
}

const autoRouter = const AutoRouter();

// initial route will have an explicit name of "/"
// there could be only one initial route per navigator.
class Initial {
  const Initial();
}

const initial = const Initial();

class MaterialRoute {
  // initial route will have an explicit name of "/"
// there could be only one initial route per navigator.
  final bool initial;

  /// passed to the fullscreenDialog property in [MaterialPageRoute]
  final bool fullscreenDialog;

  /// passed to the maintainState property in [MaterialPageRoute]
  final bool maintainState;

  const MaterialRoute(
      {this.initial, this.fullscreenDialog, this.maintainState});
}

// forces usage of CupertinoPageRoute instead of MaterialPageRoute
class CupertinoRoute {
  // initial route will have an explicit name of "/"
// there could be only one initial route per navigator.
  final bool initial;

  /// passed to the fullscreenDialog property in [CupertinoPageRoute]
  final bool fullscreenDialog;

  /// passed to the maintainState property in [CupertinoPageRoute]
  final bool maintainState;

  /// passed to the title property in [CupertinoPageRoute]
  final String title;

  const CupertinoRoute({
    this.fullscreenDialog,
    this.maintainState,
    this.initial,
    this.title,
  });
}

class CustomRoute {
  // initial route will have an explicit name of "/"
// there could be only one initial route per navigator.
  final bool initial;

  /// passed to the fullscreenDialog property in [PageRouteBuilder]
  final bool fullscreenDialog;

  /// passed to the maintainState property in [PageRouteBuilder]
  final bool maintainState;

  /// this builder function is passed to the transition builder
  /// function in [PageRouteBuilder]
  ///
  /// I couldn't type this function from here but it should match
  /// typedef [RouteTransitionsBuilder] = Widget Function(BuildContext context, Animation<double> animation,
  /// Animation<double> secondaryAnimation, Widget child);
  ///
  /// you should only reference the function so
  /// the generator can import it into router.dart
  final Function transitionsBuilder;

  /// route transition duration in milliseconds
  /// is passed to [PageRouteBuilder]
  /// this property is ignored unless a [transitionBuilder] is provided
  final int durationInMilliseconds;

  /// passed to the opaque property in [PageRouteBuilder]
  final bool opaque;

  /// passed to the barrierDismissible property in [PageRouteBuilder]
  final bool barrierDismissible;

  const CustomRoute({
    this.fullscreenDialog,
    this.maintainState,
    this.initial,
    this.transitionsBuilder,
    this.durationInMilliseconds,
    this.opaque,
    this.barrierDismissible,
  });
}
