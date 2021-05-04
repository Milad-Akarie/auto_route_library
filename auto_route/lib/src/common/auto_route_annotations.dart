class AutoRouterAnnotation {
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
  final String? replaceInRouteName;

  const AutoRouterAnnotation._(
    this.routes,
    this.preferRelativeImports, {
    this.replaceInRouteName,
  });
}

/// Defaults created routes to MaterialPageRoute unless
/// overridden by AutoRoute
class MaterialAutoRouter extends AutoRouterAnnotation {
  const MaterialAutoRouter({
    bool preferRelativeImports = true,
    required List<AutoRoute> routes,
    String? replaceInRouteName,
  }) : super._(
          routes,
          preferRelativeImports,
          replaceInRouteName: replaceInRouteName,
        );
}

/// Defaults created routes to CupertinoPageRoute unless
/// overridden by AutoRoute
class CupertinoAutoRouter extends AutoRouterAnnotation {
  const CupertinoAutoRouter({
    bool preferRelativeImports = true,
    required List<AutoRoute> routes,
    String? replaceInRouteName,
  }) : super._(
          routes,
          preferRelativeImports,
          replaceInRouteName: replaceInRouteName,
        );
}

class AdaptiveAutoRouter extends AutoRouterAnnotation {
  const AdaptiveAutoRouter({
    bool preferRelativeImports = false,
    required List<AutoRoute> routes,
    String? replaceInRouteName,
  }) : super._(
          routes,
          preferRelativeImports,
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
  final Function? transitionsBuilder;

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
  final Function? customRouteBuilder;

  /// route transition duration in milliseconds
  /// is passed to [PageRouteBuilder]
  /// this property is ignored unless a [transitionBuilder] is provided
  final int? durationInMilliseconds;

  /// route reverse transition duration in milliseconds
  /// is passed to [PageRouteBuilder]
  /// this property is ignored unless a [transitionBuilder] is provided
  final int? reverseDurationInMilliseconds;

  /// passed to the opaque property in [PageRouteBuilder]
  final bool opaque;

  /// passed to the barrierDismissible property in [PageRouteBuilder]
  final bool barrierDismissible;

  const CustomAutoRouter(
      {this.transitionsBuilder,
      this.barrierDismissible = false,
      this.durationInMilliseconds,
      this.reverseDurationInMilliseconds,
      this.customRouteBuilder,
      this.opaque = true,
      required List<AutoRoute> routes,
      bool preferRelativeImports = true,
      String? replaceInRouteName})
      : super._(
          routes,
          preferRelativeImports,
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

  final List<AutoRoute>? children;

  /// route path name which will be assigned to the given variable name
  /// const homeScreen = '[path]';
  /// if null a kabab cased variable name
  /// prefixed with '/' will be used;
  /// homeScreen -> home-screen

  final String? path;
  final String? name;

  final Type? page;

  final List<Type>? guards;

  final bool fullMatch;

  /// if true path is used as page key instead of name
  final bool usesPathAsKey;

  const AutoRoute(
      {this.page,
      this.initial = false,
      this.guards,
      this.fullscreenDialog = false,
      this.maintainState = true,
      this.fullMatch = false,
      this.path,
      this.name,
      this.usesPathAsKey = false,
      this.children});
}

class RedirectRoute extends AutoRoute {
  final String redirectTo;

  const RedirectRoute({
    required String path,
    required this.redirectTo,
  }) : super(path: path, fullMatch: true);
}

class MaterialRoute<T> extends AutoRoute<T> {
  const MaterialRoute(
      {String? path,
      required Type page,
      bool initial = false,
      bool fullscreenDialog = false,
      bool maintainState = true,
      bool fullMatch = false,
      String? name,
      List<Type>? guards,
      bool usesPathAsKey = false,
      List<AutoRoute>? children})
      : super(
          page: page,
          guards: guards,
          fullMatch: fullMatch,
          initial: initial,
          usesPathAsKey: usesPathAsKey,
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
  final String? title;

  const CupertinoRoute(
      {bool initial = false,
      bool fullscreenDialog = false,
      bool maintainState = true,
      String? path,
      this.title,
      String? name,
      bool fullMatch = false,
      required Type page,
      List<Type>? guards,
      bool usesPathAsKey = false,
      List<AutoRoute>? children})
      : super(
          initial: initial,
          fullscreenDialog: fullscreenDialog,
          maintainState: maintainState,
          path: path,
          name: name,
          usesPathAsKey: usesPathAsKey,
          fullMatch: fullMatch,
          page: page,
          guards: guards,
          children: children,
        );
}

class AdaptiveRoute<T> extends AutoRoute<T> {
  const AdaptiveRoute(
      {bool initial = false,
      bool fullscreenDialog = false,
      bool maintainState = true,
      String? name,
      String? path,
      bool usesPathAsKey = false,
      bool fullMatch = false,
      this.cupertinoPageTitle,
      required Type page,
      List<Type>? guards,
      List<AutoRoute>? children})
      : super(
            initial: initial,
            fullscreenDialog: fullscreenDialog,
            maintainState: maintainState,
            path: path,
            usesPathAsKey: usesPathAsKey,
            name: name,
            fullMatch: fullMatch,
            page: page,
            guards: guards,
            children: children);

  /// passed to the title property in [CupertinoPageRoute]
  final String? cupertinoPageTitle;
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
  final Function? transitionsBuilder;

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
  final Function? customRouteBuilder;

  /// route transition duration in milliseconds
  /// is passed to [PageRouteBuilder]
  /// this property is ignored unless a [transitionBuilder] is provided
  final int? durationInMilliseconds;

  /// route reverse transition duration in milliseconds
  /// is passed to [PageRouteBuilder]
  /// this property is ignored unless a [transitionBuilder] is provided
  final int? reverseDurationInMilliseconds;

  /// passed to the opaque property in [PageRouteBuilder]
  final bool opaque;

  /// passed to the barrierDismissible property in [PageRouteBuilder]
  final bool barrierDismissible;

  /// passed to the barrierLabel property in [PageRouteBuilder]
  final String? barrierLabel;

  const CustomRoute({
    bool initial = false,
    bool fullscreenDialog = false,
    bool maintainState = true,
    String? name,
    String? path,
    bool fullMatch = false,
    required Type page,
    List<Type>? guards,
    bool usesPathAsKey = false,
    List<AutoRoute>? children,
    this.customRouteBuilder,
    this.barrierLabel,
    this.transitionsBuilder,
    this.durationInMilliseconds,
    this.reverseDurationInMilliseconds,
    this.opaque = true,
    this.barrierDismissible = false,
  }) : super(
            initial: initial,
            fullscreenDialog: fullscreenDialog,
            maintainState: maintainState,
            usesPathAsKey: usesPathAsKey,
            path: path,
            name: name,
            fullMatch: fullMatch,
            page: page,
            guards: guards,
            children: children);
}

class PathParam {
  final String? name;

  const PathParam([this.name]);
}

const pathParam = PathParam();

class QueryParam {
  final String? name;

  const QueryParam([this.name]);
}

const queryParam = QueryParam();
