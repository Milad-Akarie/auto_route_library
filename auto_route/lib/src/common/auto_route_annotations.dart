import 'package:meta/meta.dart' show optionalTypeArgs;
import 'package:meta/meta_meta.dart' show Target, TargetKind;

/// Classes annotated with AutoRouteConfig will generate
/// an abstract class that extends [RootStackRouter] that
/// can be extended by the annotated class to be used as the RootRouter of the App
@Target({TargetKind.classType})
class AutoRouterConfig {
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
  /// defaults to 'Page|Screen,Route', ignored if a route name is provided.
  final String? replaceInRouteName;

  /// Use for web for lazy loading other routes
  /// more info https://dart.dev/guides/language/language-tour#deferred-loading
  /// defaults to false
  final bool deferredLoading;

  /// Only generated files exist in provided directories will be processed
  /// defaults = const ['lib']
  final List<String> generateForDir;

  /// Whether to generate equality operator and hashCode for route args
  ///
  /// defaults to true
  final bool argsEquality;

  /// default constructor
  const AutoRouterConfig({
    this.replaceInRouteName = 'Page|Screen,Route',
    this.deferredLoading = false,
    this.generateForDir = const ['lib'],
    this.argsEquality = true,
  });
}

/// This annotation is used to mark flutter widgets as routable pages
/// by enabling the router to construct them.
///
/// defaults to dynamic
@optionalTypeArgs
@Target({TargetKind.classType})
class RoutePage {
  /// The name of the generated route
  /// if not provided, a name will be generated from class name
  /// and maybe altered by [replaceInRouteName]
  final String? name;

  /// Use for web for lazy loading
  /// more info https://dart.dev/guides/language/language-tour#deferred-loading
  /// defaults to false
  final bool? deferredLoading;

  /// default constructor
  const RoutePage({
    this.name,
    this.deferredLoading,
  });
}

/// default routePage
const routePage = RoutePage();

/// this annotation is used to make parameters that's supposed
/// to take their values from the dynamic segments of a path
@Target({TargetKind.parameter})
class PathParam {
  /// name of the dynamic segment declared in path
  /// e.g /path/:id -> name = id
  ///
  /// if not provided the name of the parameter will be used
  /// (@PathParam() int id); -> name = id
  final String? name;

  // ignore: unused_field
  final bool _inherited;

  /// default constructor
  const PathParam([this.name]) : _inherited = false;

  /// Use this constructor to inherit a dynamic-segment
  /// from a parent path
  const PathParam.inherit([this.name]) : _inherited = true;
}

/// default PathParam()
const pathParam = PathParam();

/// default PathParam.inherit()
const inheritPathParam = PathParam.inherit();

/// this annotation is used to make parameters that's supposed
/// to take their values from query params of the url
///
/// e.g /path?foo=bar
@Target({TargetKind.parameter})
class QueryParam {
  /// name of the query param from url
  ///
  /// if not provided the name of the parameter will be used
  /// (@QueryParam() String foo); -> name = foo
  final String? name;

  /// default constructor
  const QueryParam([this.name]);
}

/// default QueryParam()
const queryParam = QueryParam();

/// this annotation is used to mark a parameter as a  url fragment
/// e.g /path#foo
///
/// so it can take its value from the url fragment automatically
@Target({TargetKind.parameter})
class UrlFragment {
  const UrlFragment._();
}

/// default UrlFragment
const urlFragment = UrlFragment._();
