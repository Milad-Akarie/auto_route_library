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

  /// if true relative imports will be generated
  /// when possible
  /// defaults to true
  final bool preferRelativeImports;

  final List<AutoRoute> routes;

  const AutoRouterAnnotation._(
    this.generateNavigationHelperExtension,
    this.routesClassName,
    this.routePrefix,
    this.routes,
    this.preferRelativeImports,
  ) : assert(routes != null);
}

// Defaults created routes to MaterialPageRoute unless
// overridden by AutoRoute annotation
class MaterialAutoRouter extends AutoRouterAnnotation {
  const MaterialAutoRouter({
    bool generateNavigationHelperExtension,
    String routesClassName,
    String pathPrefix,
    bool preferRelativeImports,
    @required List<AutoRoute> routes,
  }) : super._(
          generateNavigationHelperExtension,
          routesClassName,
          pathPrefix,
          routes,
          preferRelativeImports,
        );
}

class MaterialRouter extends AutoRouterAnnotation {
  const MaterialRouter({
    bool generateNavigationHelperExtension,
    String routesClassName,
    String pathPrefix,
    @required List<AutoRoute> routes,
    bool preferRelativeImports,
  }) : super._(
          generateNavigationHelperExtension,
          routesClassName,
          pathPrefix,
          routes,
          preferRelativeImports,
        );
}

// Defaults created routes to CupertinoPageRoute unless
// overridden by AutoRoute annotation
class CupertinoAutoRouter extends AutoRouterAnnotation {
  const CupertinoAutoRouter({
    bool generateNavigationHelperExtension,
    String routesClassName,
    String pathPrefix,
    bool preferRelativeImports,
    @required List<AutoRoute> routes,
  }) : super._(
          generateNavigationHelperExtension,
          routesClassName,
          pathPrefix,
          routes,
          preferRelativeImports,
        );
}

class AdaptiveAutoRouter extends AutoRouterAnnotation {
  const AdaptiveAutoRouter({
    bool generateNavigationHelperExtension,
    String routesClassName,
    String pathPrefix,
    bool preferRelativeImports,
    @required List<AutoRoute> routes,
  }) : super._(
          generateNavigationHelperExtension,
          routesClassName,
          pathPrefix,
          routes,
          preferRelativeImports,
        );
}

// Defaults created routes to PageRouteBuilder unless
// overridden by AutoRoute annotation
class CustomAutoRouter extends AutoRouterAnnotation {
  /// this builder function is passed to the transition builder
  /// function in [PageRouteBuilder]
  ///
  /// I couldn't type this function from here, but it should match
  /// typedef [RouteTransitionsBuilder] = Widget Function(BuildContext context, Animation<double> animation,
  /// Animation<double> secondaryAnimation, Widget child);
  ///
  /// you should only reference the function so
  /// the generator can import it into router_base.dart
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
    this.transitionsBuilder,
    this.barrierDismissible,
    this.durationInMilliseconds,
    this.opaque,
    bool generateNavigationHelperExtension,
    String routesClassName,
    String pathPrefix,
    @required List<AutoRoute> routes,
    bool preferRelativeImports,
  }) : super._(
          generateNavigationHelperExtension,
          routesClassName,
          pathPrefix,
          routes,
          preferRelativeImports,
        );
}

// [T] is the results type returned
/// from this page route MaterialPageRoute<T>()
/// defaults to dynamic

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
  final String name;

  final Type page;

  final List<Type> guards;

  const AutoRoute(
      {@required this.page,
      this.initial,
      this.guards,
      this.fullscreenDialog,
      this.maintainState,
      this.path,
      this.name,
      this.children});
}

class MaterialRoute<T> extends AutoRoute<T> {
  const MaterialRoute(
      {String path,
      @required Type page,
      bool initial,
      bool fullscreenDialog,
      bool maintainState,
      String name,
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
          name: name,
        );
}

// forces usage of CupertinoPageRoute instead of MaterialPageRoute
class CupertinoRoute<T> extends AutoRoute<T> {
  /// passed to the title property in [CupertinoPageRoute]
  final String title;

  const CupertinoRoute(
      {bool initial,
      bool fullscreenDialog,
      bool maintainState,
      String path,
      this.title,
      String name,
      @required Type page,
      List<Type> guards,
      List<AutoRoute> children})
      : super(
            initial: initial,
            fullscreenDialog: fullscreenDialog,
            maintainState: maintainState,
            path: path,
            name: name,
            page: page,
            guards: guards,
            children: children);
}

class AdaptiveRoute<T> extends AutoRoute<T> {
  const AdaptiveRoute(
      {bool initial,
      bool fullscreenDialog,
      bool maintainState,
      String name,
      String path,
      Type returnType,
      this.cupertinoPageTitle,
      @required Type page,
      List<Type> guards,
      List<AutoRoute> children})
      : super(
            initial: initial,
            fullscreenDialog: fullscreenDialog,
            maintainState: maintainState,
            path: path,
            name: name,
            page: page,
            guards: guards,
            children: children);

  /// passed to the title property in [CupertinoPageRoute]
  final String cupertinoPageTitle;
}

class CustomRoute<T> extends AutoRoute<T> {
  /// this builder function is passed to the transition builder
  /// function in [PageRouteBuilder]
  ///
  /// I couldn't type this function from here but it should match
  /// typedef [RouteTransitionsBuilder] = Widget Function(BuildContext context, Animation<double> animation,
  /// Animation<double> secondaryAnimation, Widget child);
  ///
  /// you should only reference the function so
  /// the generator can import it into router_base.dart
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
    String path,
    @required Type page,
    List<Type> guards,
    List<AutoRoute> children,
    this.transitionsBuilder,
    this.durationInMilliseconds,
    this.opaque,
    this.barrierDismissible,
  }) : super(
            initial: initial,
            fullscreenDialog: fullscreenDialog,
            maintainState: maintainState,
            path: path,
            name: name,
            page: page,
            guards: guards,
            children: children);
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
