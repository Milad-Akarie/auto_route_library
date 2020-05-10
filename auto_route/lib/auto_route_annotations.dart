class AutoRouter {
  // if true a Navigator extension will be generated with
  // helper push methods of all routes
  final bool generateNavigationHelperExtension;

  // defaults to true
  final bool generateArgsHolderForSingleParameterRoutes;

  // defaults to 'Routes'
  final String routesClassName;

  //This is the prefix for each Route String that is generated
  // initial routes will always be named '/'
  // defaults to '/'
  final String routePrefix;

  const AutoRouter._(
    this.generateNavigationHelperExtension,
    this.generateArgsHolderForSingleParameterRoutes,
    this.routesClassName,
    this.routePrefix,
  );
}

// Defaults created routes to MaterialPageRoute unless
// overridden by AutoRoute annotation
class MaterialAutoRouter extends AutoRouter {
  const MaterialAutoRouter(
      {bool generateNavigationHelperExtension,
      bool generateArgsHolderForSingleParameterRoutes,
      String routesClassName,
      String routePrefix})
      : super._(
            generateNavigationHelperExtension,
            generateArgsHolderForSingleParameterRoutes,
            routesClassName,
            routePrefix);
}

// Defaults created routes to CupertinoPageRoute unless
// overridden by AutoRoute annotation
class CupertinoAutoRouter extends AutoRouter {
  const CupertinoAutoRouter({
    bool generateNavigationHelperExtension,
    bool generateArgsHolderForSingleParameterRoutes,
    String routesClassName,
    String routePrefix,
  }) : super._(
          generateNavigationHelperExtension,
          generateArgsHolderForSingleParameterRoutes,
          routesClassName,
          routePrefix,
        );
}

class AdaptiveAutoRouter extends AutoRouter {
  const AdaptiveAutoRouter({
    bool generateNavigationHelperExtension,
    bool generateArgsHolderForSingleParameterRoutes,
    String routesClassName,
    String routePrefix,
  }) : super._(
          generateNavigationHelperExtension,
          generateArgsHolderForSingleParameterRoutes,
          routesClassName,
          routePrefix,
        );
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

  const CustomAutoRouter(
      {this.transitionsBuilder,
      this.barrierDismissible,
      this.durationInMilliseconds,
      this.opaque,
      bool generateNavigationHelperExtension,
      bool generateArgsHolderForSingleParameterRoutes,
      String routesClassName,
      String routePrefix})
      : super._(
          generateNavigationHelperExtension,
          generateArgsHolderForSingleParameterRoutes,
          routesClassName,
          routePrefix,
        );
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

class AdaptiveRoute extends AutoRoute {
  const AdaptiveRoute({
    bool initial,
    bool fullscreenDialog,
    bool maintainState,
    String name,
    Type returnType,
    this.cupertinoPageTitle,
  }) : super._(
          initial: initial,
          fullscreenDialog: fullscreenDialog,
          maintainState: maintainState,
          name: name,
          returnType: returnType,
        );

  /// passed to the title property in [CupertinoPageRoute]
  final String cupertinoPageTitle;
}

const adaptiveRoute = const AdaptiveRoute();

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

/// Widgets annotated with [unknownRoute] must have a default constructor
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
