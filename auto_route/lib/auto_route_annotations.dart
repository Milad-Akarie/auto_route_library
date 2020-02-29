class AutoRouter {
  final bool generateRouteList;

  const AutoRouter._(this.generateRouteList);
}

// Defaults created routes to MaterialPageRoute unless
// overridden by AutoRoute annotation
class MaterialAutoRouter extends AutoRouter {
  const MaterialAutoRouter({bool generateRouteList})
      : super._(generateRouteList);
}

// Defaults created routes to CupertinoPageRoute unless
// overridden by AutoRoute annotation
class CupertinoAutoRouter extends AutoRouter {
  const CupertinoAutoRouter({bool generateRouteList})
      : super._(generateRouteList);
}

// Defaults created routes to PageRouteBuilder unless
// overridden by AutoRoute annotation
class CustomAutoRouter extends AutoRouter {
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
  const CustomAutoRouter({
    bool generateRouteList,
    this.transitionsBuilder,
    this.barrierDismissible,
    this.durationInMilliseconds,
    this.opaque,
  }) : super._(generateRouteList);
}

class AutoRoute {
  // initial route will have an explicit name of "/"
// there could be only one initial route per navigator.
  final bool initial;

  /// passed to the fullscreenDialog property in [MaterialPageRoute]
  final bool fullscreenDialog;

  /// passed to the maintainState property in [MaterialPageRoute]
  final bool maintainState;

  /// route path name which will be assigned to the given variable name
  /// const homeScreen = '[name]';
  /// if null a kabab cased variable name
  /// prefixed with '/' will be used;
  /// homeScreen -> home-screen
  final String name;

  // the results type returned
  /// from this page route MaterialPageRoute<[returnType]>()
  /// defaults to dynamic
  final Type returnType;

  const AutoRoute._(
      {this.initial,
      this.fullscreenDialog,
      this.maintainState,
      this.name,
      this.returnType});
}

class MaterialRoute extends AutoRoute {
  const MaterialRoute({
    bool initial,
    bool fullscreenDialog,
    bool maintainState,
    String name,
    Type returnType,
  }) : super._(
          initial: initial,
          fullscreenDialog: fullscreenDialog,
          maintainState: maintainState,
          name: name,
          returnType: returnType,
        );
}

const materialRoute = const MaterialRoute();
// initial route will have an explicit name of "/"
// there could be only one initial route per navigator.
const initial = const AutoRoute._(initial: true);

// forces usage of CupertinoPageRoute instead of MaterialPageRoute
class CupertinoRoute extends AutoRoute {
  /// passed to the title property in [CupertinoPageRoute]
  final String title;

  const CupertinoRoute({
    bool initial,
    bool fullscreenDialog,
    bool maintainState,
    String name,
    this.title,
    Type returnType,
  }) : super._(
          initial: initial,
          fullscreenDialog: fullscreenDialog,
          maintainState: maintainState,
          name: name,
          returnType: returnType,
        );
}

const cupertinoRoute = const CupertinoRoute();

class CustomRoute extends AutoRoute {
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
    bool initial,
    bool fullscreenDialog,
    bool maintainState,
    String name,
    this.transitionsBuilder,
    this.durationInMilliseconds,
    this.opaque,
    this.barrierDismissible,
    Type returnType,
  }) : super._(
          initial: initial,
          fullscreenDialog: fullscreenDialog,
          maintainState: maintainState,
          name: name,
          returnType: returnType,
        );
}

/// Widgets annotated with [unknowRoute] must have a defualt constructor
/// that takes in one positional String Parameter, MyUnknownRoute(String routeName)
class UnknownRoute {
  const UnknownRoute._();
}

const unknownRoute = const UnknownRoute._();

// holds RouteGuard info
class GuardedBy {
  final List<Type> guards;

  const GuardedBy(this.guards);
}
