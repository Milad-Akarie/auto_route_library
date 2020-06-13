import 'package:meta/meta.dart';

class AutoRouterAnnotation {
  // if true a Navigator extension will be generated with
  // helper push methods of all routes
  final bool generateNavigationHelperExtension;

  // defaults to 'Routes'
  final String routesClassName;

  //This is the prefix for each Route String that is generated
  // initial routes will always be named '/'
  // defaults to '/'
  final String routePrefix;

  const AutoRouterAnnotation._(
    this.generateNavigationHelperExtension,
    this.routesClassName,
    this.routePrefix,
  );
}

// Defaults created routes to MaterialPageRoute unless
// overridden by AutoRoute annotation
class MaterialAutoRouter extends AutoRouterAnnotation {
  const MaterialAutoRouter({
    bool generateNavigationHelperExtension,
    bool generateArgsHolderForSingleParameterRoutes,
    String routesClassName,
    String routePrefix,
  }) : super._(generateNavigationHelperExtension, routesClassName, routePrefix);
}

// Defaults created routes to CupertinoPageRoute unless
// overridden by AutoRoute annotation
class CupertinoAutoRouter extends AutoRouterAnnotation {
  const CupertinoAutoRouter({
    bool generateNavigationHelperExtension,
    bool generateArgsHolderForSingleParameterRoutes,
    String routesClassName,
    String routePrefix,
  }) : super._(
          generateNavigationHelperExtension,
          routesClassName,
          routePrefix,
        );
}

class AdaptiveAutoRouter extends AutoRouterAnnotation {
  const AdaptiveAutoRouter({
    bool generateNavigationHelperExtension,
    bool generateArgsHolderForSingleParameterRoutes,
    String routesClassName,
    String routePrefix,
  }) : super._(
          generateNavigationHelperExtension,
          routesClassName,
          routePrefix,
        );
}

// Defaults created routes to PageRouteBuilder unless
// overridden by AutoRoute annotation
class CustomAutoRouter extends AutoRouterAnnotation {
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
          routesClassName,
          routePrefix,
        );
}

class AutoRoute<T> {
  // initial route will have an explicit name of "/"
  // there could be only one initial route per navigator.
  final bool initial;

  /// passed to the fullscreenDialog property in [MaterialPageRoute]
  final bool fullscreenDialog;

  /// passed to the maintainState property in [MaterialPageRoute]
  final bool maintainState;
  final List<AutoRoute> children;

  /// route path name which will be assigned to the given variable name
  /// const homeScreen = '[path]';
  /// if null a kabab cased variable name
  /// prefixed with '/' will be used;
  /// homeScreen -> home-screen

  final String path;

  final Type page;

  final List<Type> guards;

  // the results type returned
  /// from this page route MaterialPageRoute<[returnType]>()
  /// defaults to dynamic
  final Type returnType;

  const AutoRoute({this.page, this.initial, this.guards, this.fullscreenDialog, this.maintainState, this.path, this.returnType, this.children});
}

class MaterialRoute<T> extends AutoRoute<T> {
  const MaterialRoute(
      {String path,
      @required Type page,
      bool initial,
      bool fullscreenDialog,
      bool maintainState,
      Type returnType,
      List<Type> guards,
      List<AutoRoute> children})
      : super(
          page: page,
          guards: guards,
          initial: initial,
          fullscreenDialog: fullscreenDialog,
          maintainState: maintainState,
          path: path,
          children: children,
          returnType: returnType,
        );
}

// initial route will have an explicit name of "/"
// there could be only one initial route per navigator.
const initial = const AutoRoute(initial: true);

// forces usage of CupertinoPageRoute instead of MaterialPageRoute
class CupertinoRoute extends AutoRoute {
  /// passed to the title property in [CupertinoPageRoute]
  final String title;

  const CupertinoRoute({
    bool initial,
    bool fullscreenDialog,
    bool maintainState,
    @Deprecated('replaced with path') String name,
    String path,
    this.title,
    Type returnType,
  }) : super(
          initial: initial,
          fullscreenDialog: fullscreenDialog,
          maintainState: maintainState,
          path: path ?? name,
          returnType: returnType,
        );
}

const cupertinoRoute = const CupertinoRoute();

class AdaptiveRoute extends AutoRoute {
  const AdaptiveRoute({
    bool initial,
    bool fullscreenDialog,
    bool maintainState,
    @Deprecated('replaced with path') String name,
    String path,
    Type returnType,
    this.cupertinoPageTitle,
  }) : super(
          initial: initial,
          fullscreenDialog: fullscreenDialog,
          maintainState: maintainState,
          path: path ?? name,
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
    @Deprecated('replaced with path') String name,
    String path,
    this.transitionsBuilder,
    this.durationInMilliseconds,
    this.opaque,
    this.barrierDismissible,
    Type returnType,
  }) : super(
          initial: initial,
          fullscreenDialog: fullscreenDialog,
          maintainState: maintainState,
          path: path ?? name,
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

class RoutesList {
  // this will be ignored if path is provided
  final String namePrefix;

  const RoutesList({this.namePrefix});
}

class PathParam {
  final String name;

  const PathParam([this.name]);
}
const pathParam = PathParam();

class QueryParam {
  final String name;

  const QueryParam([this.name]);
}

const queryParam = QueryParam();

