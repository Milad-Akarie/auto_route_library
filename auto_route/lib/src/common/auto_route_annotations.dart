import 'package:meta/meta.dart' show required;

class AutoRouterAnnotation {
  /// This has no effect if [usesLegacyGenerator] is true
  ///
  /// if true a Navigator extension will be generated with
  /// helper push methods of all routes

  final bool generateNavigationHelperExtension;

  /// This has no effect if [usesLegacyGenerator] is true
  ///
  /// defaults to 'Routes'
  final String routesClassName;

  /// This is the prefix for each Route String that is generated
  /// initial routes will always be named '/'
  /// defaults to '/'
  /// it has no effect unless [usesLegacyGenerator] is true
  final String routePrefix;

  /// if true legacy generator that
  /// uses ExtendedNavigator will be used instead
  final bool usesLegacyGenerator;

  /// if true relative imports will be generated
  /// when possible
  /// defaults to true
  final bool preferRelativeImports;

  final List<AutoRoute> routes;

  /// Auto generated route names can be a bit long with
  /// the [Route] suffix
  /// e.g ProductDetailsPage would be ProductDetailsPageRoute
  ///
  /// You can replace some relative parts in your route names
  /// by providing a replacement in the follow pattern
  /// [whatToReplace,replacement]
  /// what to replace and the replacement should be
  /// separated with a comma [,]
  /// e.g 'Page,Route'
  /// so ProductDetailsPage would be ProductDetailsRoute
  ///
  /// defaults no null, ignored if a route name is provided.
  final String replaceInRouteName;

  const AutoRouterAnnotation._(
    this.generateNavigationHelperExtension,
    this.routesClassName,
    this.routePrefix,
    this.routes,
    this.preferRelativeImports, {
    this.replaceInRouteName,
    this.usesLegacyGenerator,
  }) : assert(routes != null);
}

/// Defaults created routes to MaterialPageRoute unless
/// overridden by AutoRoute
class MaterialAutoRouter extends AutoRouterAnnotation {
  const MaterialAutoRouter({
    bool generateNavigationHelperExtension,
    String routesClassName,
    String pathPrefix,
    bool preferRelativeImports,
    @required List<AutoRoute> routes,
    bool usesLegacyGenerator,
    String replaceInRouteName,
  }) : super._(
          generateNavigationHelperExtension,
          routesClassName,
          pathPrefix,
          routes,
          preferRelativeImports,
          replaceInRouteName: replaceInRouteName,
          usesLegacyGenerator: usesLegacyGenerator,
        );
}

/// Defaults created routes to CupertinoPageRoute unless
/// overridden by AutoRoute
class CupertinoAutoRouter extends AutoRouterAnnotation {
  const CupertinoAutoRouter({
    bool generateNavigationHelperExtension,
    String routesClassName,
    String pathPrefix,
    bool preferRelativeImports,
    @required List<AutoRoute> routes,
    bool usesLegacyGenerator,
    String replaceInRouteName,
  }) : super._(
          generateNavigationHelperExtension,
          routesClassName,
          pathPrefix,
          routes,
          preferRelativeImports,
          replaceInRouteName: replaceInRouteName,
          usesLegacyGenerator: usesLegacyGenerator,
        );
}

class AdaptiveAutoRouter extends AutoRouterAnnotation {
  const AdaptiveAutoRouter({
    bool generateNavigationHelperExtension,
    String routesClassName,
    String pathPrefix,
    bool preferRelativeImports,
    @required List<AutoRoute> routes,
    bool usesLegacyGenerator,
    String replaceInRouteName,
  }) : super._(
          generateNavigationHelperExtension,
          routesClassName,
          pathPrefix,
          routes,
          preferRelativeImports,
          usesLegacyGenerator: usesLegacyGenerator,
          replaceInRouteName: replaceInRouteName,
        );
}

/// Defaults created routes to PageRouteBuilder unless
/// overridden by AutoRoute
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

  /// This builder function is passed to customRouteBuilder property
  /// in [CustomPage]
  ///
  /// I couldn't type this function from here but it should match
  /// typedef [CustomRouteBuilder] = Route Function(BuildContext context, CustomPage page);
  /// you should only reference the function when passing it so
  /// the generator can import it into the generated file
  ///
  /// this builder function accepts a BuildContext and a CustomPage
  /// that has all the other properties assigned to it
  /// so using them then is totally up to you.
  final Function customRouteBuilder;

  /// route transition duration in milliseconds
  /// is passed to [PageRouteBuilder]
  /// this property is ignored unless a [transitionBuilder] is provided
  final int durationInMilliseconds;

  /// route reverse transition duration in milliseconds
  /// is passed to [PageRouteBuilder]
  /// this property is ignored unless a [transitionBuilder] is provided
  final int reverseDurationInMilliseconds;

  /// passed to the opaque property in [PageRouteBuilder]
  final bool opaque;

  /// passed to the barrierDismissible property in [PageRouteBuilder]
  final bool barrierDismissible;

  const CustomAutoRouter(
      {this.transitionsBuilder,
      this.barrierDismissible,
      this.durationInMilliseconds,
      this.reverseDurationInMilliseconds,
      this.customRouteBuilder,
      this.opaque,
      bool generateNavigationHelperExtension,
      String routesClassName,
      String pathPrefix,
      @required List<AutoRoute> routes,
      bool preferRelativeImports,
      bool usesLegacyGenerator,
      String replaceInRouteName})
      : super._(
          generateNavigationHelperExtension,
          routesClassName,
          pathPrefix,
          routes,
          preferRelativeImports,
          usesLegacyGenerator: usesLegacyGenerator,
          replaceInRouteName: replaceInRouteName,
        );
}

/// [T] is the results type returned
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

  final bool fullMatch;
  final bool usesTabsRouter;

  const AutoRoute(
      {this.page,
      this.initial,
      this.guards,
      this.usesTabsRouter,
      this.fullscreenDialog,
      this.maintainState,
      this.fullMatch,
      this.path,
      this.name,
      this.children});
}

class RedirectRoute extends AutoRoute {
  final String redirectTo;

  const RedirectRoute({
    @required String path,
    @required this.redirectTo,
  })  : assert(redirectTo != null),
        super(path: path, fullMatch: true);
}

class MaterialRoute<T> extends AutoRoute<T> {
  const MaterialRoute(
      {String path,
      @required Type page,
      bool initial,
      bool fullscreenDialog,
      bool maintainState,
      bool fullMatch,
      bool usesTabsRouter,
      String name,
      List<Type> guards,
      List<AutoRoute> children})
      : super(
          page: page,
          guards: guards,
          fullMatch: fullMatch,
          initial: initial,
          fullscreenDialog: fullscreenDialog,
          maintainState: maintainState,
          path: path,
          children: children,
          name: name,
          usesTabsRouter: usesTabsRouter,
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
      bool fullMatch,
      @required Type page,
      bool usesTabsRouter,
      List<Type> guards,
      List<AutoRoute> children})
      : super(
          initial: initial,
          fullscreenDialog: fullscreenDialog,
          maintainState: maintainState,
          path: path,
          name: name,
          fullMatch: fullMatch,
          page: page,
          guards: guards,
          children: children,
          usesTabsRouter: usesTabsRouter,
        );
}

class AdaptiveRoute<T> extends AutoRoute<T> {
  const AdaptiveRoute(
      {bool initial,
      bool fullscreenDialog,
      bool maintainState,
      String name,
      String path,
      bool fullMatch,
      bool usesTabsRouter,
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
            usesTabsRouter: usesTabsRouter,
            name: name,
            fullMatch: fullMatch,
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
  /// the generator can import it into the generated file
  final Function transitionsBuilder;

  /// this builder function is passed to customRouteBuilder property
  /// in [CustomPage]
  ///
  /// I couldn't type this function from here but it should match
  /// typedef [CustomRouteBuilder] = Route Function(BuildContext context, CustomPage page);
  /// you should only reference the function when passing it so
  /// the generator can import it into the generated file
  ///
  /// this builder function accepts a BuildContext and a CustomPage
  /// that has all the other properties assigned to it
  /// so using them then is totally up to you.
  final Function customRouteBuilder;

  /// route transition duration in milliseconds
  /// is passed to [PageRouteBuilder]
  /// this property is ignored unless a [transitionBuilder] is provided
  final int durationInMilliseconds;

  /// route reverse transition duration in milliseconds
  /// is passed to [PageRouteBuilder]
  /// this property is ignored unless a [transitionBuilder] is provided
  final int reverseDurationInMilliseconds;

  /// passed to the opaque property in [PageRouteBuilder]
  final bool opaque;

  /// passed to the barrierDismissible property in [PageRouteBuilder]
  final bool barrierDismissible;

  /// passed to the barrierLabel property in [PageRouteBuilder]
  final String barrierLabel;

  const CustomRoute({
    bool initial,
    bool fullscreenDialog,
    bool maintainState,
    String name,
    String path,
    bool fullMatch,
    @required Type page,
    List<Type> guards,
    bool usesTabsRouter,
    List<AutoRoute> children,
    this.customRouteBuilder,
    this.barrierLabel,
    this.transitionsBuilder,
    this.durationInMilliseconds,
    this.reverseDurationInMilliseconds,
    this.opaque,
    this.barrierDismissible,
  }) : super(
            initial: initial,
            fullscreenDialog: fullscreenDialog,
            maintainState: maintainState,
            path: path,
            name: name,
            usesTabsRouter: usesTabsRouter,
            fullMatch: fullMatch,
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
