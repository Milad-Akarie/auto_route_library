class AutoRoute {
  // optional route name
  // this should be a valid dart variable name
  //
  // if not provided (className+Route) will be generated
  final String name;

  /// passed to the fullscreenDialog property in [MaterialPageRoute]
  /// this property is ignored if a [transitionBuilder] is provided
  final bool fullscreenDialog;

  /// passed to the maintainState property in [MaterialPageRoute]
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
  final Function transitionBuilder;

  final String navigatorName;

  /// route transition duration in milliseconds
  /// is passed to [PageRouteBuilder]
  /// this property is ignored unless a [transitionBuilder] is provided
  final int durationInMilliseconds;

  const AutoRoute({
    this.name,
    this.navigatorName,
    this.fullscreenDialog,
    this.maintainState,
    this.transitionBuilder,
    this.durationInMilliseconds,
  });
}

// initial route will have an explicit name of "/"
// there could be only one initial route.
class InitialRoute extends AutoRoute {
  const InitialRoute({String navigatorName}) : super(navigatorName: navigatorName);
}

const initialRoute = const InitialRoute();
