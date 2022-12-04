import 'package:meta/meta.dart' show optionalTypeArgs;

class AutoRouterAnnotation {
  /// if true relative imports will be generated
  /// when possible
  /// defaults to true
  final bool preferRelativeImports;


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
  /// defaults to null, ignored if a route name is provided.
  final String? replaceInRouteName;

  /// Use for web for lazy loading other routes
  /// more info https://dart.dev/guides/language/language-tour#deferred-loading
  final bool deferredLoading;

  const AutoRouterAnnotation({
    this.preferRelativeImports = true,
    this.replaceInRouteName,
    this.deferredLoading = false,
  });
}
//
// /// Defaults created routes to MaterialPageRoute unless
// /// overridden by AutoRoute
// class MaterialAutoRouter extends AutoRouterAnnotation {
//   const MaterialAutoRouter({
//     bool preferRelativeImports = true,
//     required List<RoutePage> routes,
//     String? replaceInRouteName,
//     bool? deferredLoading,
//   }) : super._(
//           routes,
//           preferRelativeImports,
//           replaceInRouteName: replaceInRouteName,
//           deferredLoading: deferredLoading ?? false,
//         );
// }
//
// /// Defaults created routes to CupertinoPageRoute unless
// /// overridden by AutoRoute
// class CupertinoAutoRouter extends AutoRouterAnnotation {
//   const CupertinoAutoRouter({
//     bool preferRelativeImports = true,
//     required List<RoutePage> routes,
//     String? replaceInRouteName,
//     bool? deferredLoading,
//   }) : super._(
//           routes,
//           preferRelativeImports,
//           replaceInRouteName: replaceInRouteName,
//           deferredLoading: deferredLoading ?? false,
//         );
// }
//
// class AdaptiveAutoRouter extends AutoRouterAnnotation {
//   const AdaptiveAutoRouter({
//     bool preferRelativeImports = false,
//     required List<RoutePage> routes,
//     String? replaceInRouteName,
//     bool? deferredLoading,
//   }) : super._(
//           routes,
//           preferRelativeImports,
//           replaceInRouteName: replaceInRouteName,
//           deferredLoading: deferredLoading ?? false,
//         );
// }
//
// /// Defaults created routes to PageRouteBuilder unless
// /// overridden by AutoRoute
// class CustomAutoRouter extends AutoRouterAnnotation {
//   /// this builder function is passed to the transition builder
//   /// function in [PageRouteBuilder]
//   ///
//   /// I couldn't type this function from here, but it should match
//   /// typedef [RouteTransitionsBuilder] = Widget Function(BuildContext context, Animation<double> animation,
//   /// Animation<double> secondaryAnimation, Widget child);
//   ///
//   /// you should only reference the function so
//   /// the generator can import it into router_base.dart
//   final Function? transitionsBuilder;
//
//   /// This builder function is passed to customRouteBuilder property
//   /// in [CustomPage]
//   ///
//   /// I couldn't type this function from here but it should match
//   /// typedef [CustomRouteBuilder] = Route Function(BuildContext context, CustomPage page);
//   /// you should only reference the function when passing it so
//   /// the generator can import it into the generated file
//   ///
//   /// this builder function accepts a BuildContext and a CustomPage
//   /// that has all the other properties assigned to it
//   /// so using them then is totally up to you.
//   final Function? customRouteBuilder;
//
//   /// route transition duration in milliseconds
//   /// is passed to [PageRouteBuilder]
//   /// this property is ignored unless a [transitionBuilder] is provided
//   final int? durationInMilliseconds;
//
//   /// route reverse transition duration in milliseconds
//   /// is passed to [PageRouteBuilder]
//   /// this property is ignored unless a [transitionBuilder] is provided
//   final int? reverseDurationInMilliseconds;
//
//   /// passed to the opaque property in [PageRouteBuilder]
//   final bool opaque;
//
//   /// passed to the barrierDismissible property in [PageRouteBuilder]
//   final bool barrierDismissible;
//
//   const CustomAutoRouter({
//     this.transitionsBuilder,
//     this.barrierDismissible = false,
//     this.durationInMilliseconds,
//     this.reverseDurationInMilliseconds,
//     this.customRouteBuilder,
//     this.opaque = true,
//     required List<RoutePage> routes,
//     bool preferRelativeImports = true,
//     String? replaceInRouteName,
//     bool? deferredLoading,
//   }) : super._(
//           routes,
//           preferRelativeImports,
//           replaceInRouteName: replaceInRouteName,
//           deferredLoading: deferredLoading ?? false,
//         );
// }

/// [T] is the results type returned
/// from this page route MaterialPageRoute<T>()
/// defaults to dynamic
@optionalTypeArgs
class RoutePage<T> {
  // initial route will have an explicit name of "/"
  // there could be only one initial route per navigator.
  final bool initial;

  /// route path name which will be assigned to the given variable name
  /// const homeScreen = '[path]';
  /// if null a kabab cased variable name
  /// prefixed with '/' will be used;
  /// homeScreen -> home-screen

  final String? path;
  final String? name;
  final bool fullMatch;
  final bool? deferredLoading;

  const RoutePage({
    this.initial = false,
    this.fullMatch = false,
    this.path,
    this.name,
    this.deferredLoading,
  });
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
