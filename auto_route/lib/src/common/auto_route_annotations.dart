import 'package:auto_route/src/common/param_converter.dart';
import 'package:meta/meta.dart' show optionalTypeArgs;
import 'package:meta/meta_meta.dart' show Target;

/// Classes annotated with AutoRouteConfig will generate an abstract class that
/// extends `RootStackRouter` that can be extended by the annotated class to be
/// used as the RootRouter of the App
@Target({.classType})
class AutoRouterConfig {
  /// default constructor
  const new({
    this.replaceInRouteName = 'Page|Screen,Route',
    this.deferredLoading = false,
    this.generateForDir = const ['lib'],
    this.argsEquality = true,
  });

  /// Auto generated route names can be a bit long with
  /// the `Route` suffix
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
}

/// This annotation is used to mark flutter widgets as routable pages
/// by enabling the router to construct them.
///
/// defaults to dynamic
@optionalTypeArgs
@Target({.classType})
class RoutePage {
  /// default constructor
  const new({this.name, this.deferredLoading});

  /// The name of the generated route
  /// if not provided, a name will be generated from class name
  /// and maybe altered by `replaceInRouteName`
  final String? name;

  /// Use for web for lazy loading
  /// more info https://dart.dev/guides/language/language-tour#deferred-loading
  /// defaults to false
  final bool? deferredLoading;
}

/// default routePage
const routePage = RoutePage();

/// this annotation is used to make parameters that's supposed
/// to take their values from the dynamic segments of a path
@Target({.parameter})
class PathParam {
  /// default constructor
  const new([this.name, this.converter]) : _inherited = false;

  /// Use this constructor to inherit a dynamic-segment
  /// from a parent path
  const new inherit([this.name, this.converter]) : _inherited = true;

  /// name of the dynamic segment declared in path
  /// e.g /path/:id -> name = id
  ///
  /// if not provided the name of the parameter will be used
  /// (@PathParam() int id); -> name = id
  final String? name;

  /// The converter that reads the param from its path segment and writes it
  /// back, or `null` for a type a path gives by itself: `String`, `int`,
  /// `double`, `num`, `bool` or `dynamic`.
  ///
  /// Any other type needs one, as in `@PathParam('id', userIdConverter)`;
  /// it must be a top-level `const` variable. See [ParamConverter].
  final ParamConverter<Object?>? converter;

  // Read by the generator from the annotation's source, never by Dart code.
  final bool _inherited;
}

/// default PathParam()
const pathParam = PathParam();

/// default PathParam.inherit()
const inheritPathParam = PathParam.inherit();

/// this annotation is used to make parameters that's supposed
/// to take their values from query params of the url
///
/// e.g /path?foo=bar
@Target({.parameter})
class QueryParam {
  /// default constructor
  const new([this.name, this.converter]);

  /// name of the query param from url
  ///
  /// if not provided the name of the parameter will be used
  /// (@QueryParam() String foo); -> name = foo
  final String? name;

  /// The converter that reads the param from the query and writes it back,
  /// or `null` for a type a query gives by itself: `String`, `int`,
  /// `double`, `num`, `bool`, `Object`, `dynamic`, an enum (read by its
  /// name), or a `List`, `Set` or `Iterable` of those.
  ///
  /// Any other type needs one, as in `@QueryParam('by', userIdConverter)`;
  /// it must be a top-level `const` variable. A converter on an enum
  /// replaces reading it by its name. See [ParamConverter].
  final ParamConverter<Object?>? converter;
}

/// default QueryParam()
const queryParam = QueryParam();

/// this annotation is used to mark a parameter as a  url fragment
/// e.g /path#foo
///
/// so it can take its value from the url fragment automatically
@Target({.parameter})
class UrlFragment {
  const new _();
}

/// default UrlFragment
const urlFragment = UrlFragment._();
