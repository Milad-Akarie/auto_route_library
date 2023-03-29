import 'package:meta/meta.dart' show optionalTypeArgs;

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
  final bool deferredLoading;

  /// Only files exist in provided directories will be processed
  final List<String> generateForDir;

  const AutoRouterConfig({
    this.replaceInRouteName = 'Page|Screen,Route',
    this.deferredLoading = false,
    this.generateForDir = const ['lib'],
  });
}

/// [T] is the results type returned
/// from this page route MaterialPageRoute<T>()
/// defaults to dynamic
@optionalTypeArgs
class RoutePage<T> {
  final String? name;
  final bool? deferredLoading;
  const RoutePage({
    this.name,
    this.deferredLoading,
  });
}

/// default routePage
const routePage = RoutePage();

class PathParam {
  final String? name;
  // ignore: unused_field
  final bool _inherited;

  const PathParam([this.name]) : _inherited = false;
  const PathParam.inherit([this.name]) : _inherited = true;
}

const pathParam = PathParam();
const inheritPathParam = PathParam();

class QueryParam {
  final String? name;

  const QueryParam([this.name]);
}

const queryParam = QueryParam();
