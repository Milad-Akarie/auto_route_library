class AutoRoute {
  // optional route name
  // if not provided (className+Route) will be generated
  /// this property is ignored if  [initial] is true
  /// initialRoute will be generated instead
  final String name;

//  // initial route will have an explicit name of "/"
//  // there could be only one initial route.
//  final bool initial;

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

  /// route transition duration in milliseconds
  /// is passed to [PageRouteBuilder]
  /// this property is ignored unless a [transitionBuilder] is provided
  final int durationInMilliseconds;

  const AutoRoute({
    this.name,
    this.fullscreenDialog,
    this.maintainState,
    this.transitionBuilder,
    this.durationInMilliseconds,
  });

}

class InitialRoute extends AutoRoute{
  // initial route will have an explicit name of "/"
  // there could be only one initial route.
  final bool initial = true;
  const InitialRoute();

}
const initialRoute = const InitialRoute();
