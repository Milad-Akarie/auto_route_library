import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

import '../../auto_route.dart';
import '../utils.dart';

/// Holds information of a named destination
///
/// Generated routes will extends this to make a sub-type
/// that has all the corresponding page constructor arguments,
/// it also adds a list of [initialChildren] e.g:
///
/// class BookListRoute extends PageRouteInfo {
///   const BookListRoute({List<PageRouteInfo>? children})
///    : super(name,initialChildren: children);
///
///   static const String name = 'BookListRoute';
///   static const PageInfo<void> page = PageInfo<void>(name);
/// }

@optionalTypeArgs
@immutable
class PageRouteInfo<T> {
  final String _name;

  /// The  typed arguments of the route
  ///
  /// Args are generated from the
  /// corresponding page's constructor.
  final T? args;

  /// Route page parameters can be marked as
  /// a [PathParam], and when this entity is generated
  /// it generates a corresponding parameter that's passed
  /// to this map so it can be used to build the url later on
  final Map<String, dynamic> rawPathParams;

  /// Route page parameters can be marked as
  /// a [QueryParam], and when this entity is generated
  /// it generates a corresponding parameter that's passed
  /// to this map so it can be used to build the url later on
  final Map<String, dynamic> rawQueryParams;

  /// The list of initial route entries to be matched
  /// by the sub-router when it's created
  final List<PageRouteInfo>? initialChildren;

  /// The fragment of the [Uri.fragment]
  final String fragment;

  /// Takes the value of [RouteMatch.redirectedFrom]
  /// this is only populated it's build from match [PageRouteInfo.fromMatch]
  final String? redirectedFrom;

  /// The string match from the [RouteMatch]
  final String? stringMatch;

  /// Default constructor
  const PageRouteInfo(
    this._name, {
    this.initialChildren,
    this.args,
    this.rawPathParams = const {},
    this.rawQueryParams = const {},
    String? fragment,
    this.stringMatch,
    this.redirectedFrom,
  }) : fragment = fragment ?? '';

  /// The name of the route
  String get routeName => _name;

  /// Whether this route has initial child routes
  bool get hasChildren => initialChildren?.isNotEmpty == true;

  /// Whether is route is redirected from other route
  ///
  /// redirectedFrom is only populated if this route
  /// is re-built form a route match using [PageRouteInfo.fromMatch]
  bool get fromRedirect => redirectedFrom != null;

  /// Builds and returns a new instance of Parameters with [rawPathParams]
  Parameters get pathParams => Parameters(rawPathParams);

  /// Builds and returns a new instance of Parameters with [rawQueryParams]
  Parameters get queryParams => Parameters(rawQueryParams);

  /// Expends the path by populating it's dynamic-segments with
  /// their corresponding values from [params]
  /// e.g if [template] = '/products/:id' and [params] = {'id':'5'}
  /// the result is '/products/5'
  static String expandPath(String template, Map<String, dynamic> params) {
    if (mapNullOrEmpty(params)) {
      return template;
    }
    var paramsRegex = RegExp(":(${params.keys.join('|')})");
    var path = template.replaceAllMapped(paramsRegex, (match) {
      return params[match.group(1)]?.toString() ?? '';
    });
    return path;
  }

  /// Returns a flattened list of this route and it's sub-routes
  /// e.g if we have = Route1[Route2[Route3]]
  /// the result is [Route1,Route2,Route3]
  List<PageRouteInfo> get flattened {
    return [this, if (hasChildren) ...initialChildren!.last.flattened];
  }

  /// Returns a new instance with the provided
  /// overrides
  PageRouteInfo copyWith({
    String? name,
    String? path,
    T? args,
    RouteMatch? match,
    Map<String, dynamic>? params,
    Map<String, dynamic>? queryParams,
    List<PageRouteInfo>? children,
    String? fragment,
  }) {
    if ((name == null || identical(name, _name)) &&
        (fragment == null || identical(fragment, this.fragment)) &&
        (args == null || identical(args, this.args)) &&
        (params == null || identical(params, rawPathParams)) &&
        (queryParams == null || identical(queryParams, rawQueryParams)) &&
        (children == null || identical(children, initialChildren))) {
      return this;
    }

    return PageRouteInfo(
      name ?? _name,
      args: args ?? this.args,
      rawPathParams: params ?? rawPathParams,
      rawQueryParams: queryParams ?? rawQueryParams,
      initialChildren: children ?? initialChildren,
    );
  }

  @override
  String toString() {
    return 'Route{name: $_name,  params: $rawPathParams}, children: ${initialChildren?.map((e) => e.routeName)}';
  }

  /// Creates a new instance form [RouteMatch]
  factory PageRouteInfo.fromMatch(RouteMatch match) {
    return PageRouteInfo(
      match.name,
      rawPathParams: match.pathParams.rawMap,
      rawQueryParams: match.queryParams.rawMap,
      fragment: match.fragment,
      redirectedFrom: match.redirectedFrom,
      stringMatch: match.stringMatch,
      args: match.args,
      initialChildren: match.children
          ?.map(
            (m) => PageRouteInfo.fromMatch(m),
          )
          .toList(),
    );
  }

  /// Calls [StackRouter.push] with this route on the nearest router
  Future<E?> push<E>(BuildContext context) {
    return context.router.push<E>(this);
  }

  /// Calls [StackRouter.navigate] with this route on the nearest router
  Future<void> navigate(BuildContext context) {
    return context.router.navigate(this);
  }

  /// Returns the match result of this route
  /// which internally calls [router.matcher.matchByRoute]
  RouteMatch? match(BuildContext context) {
    return context.router.match(this);
  }

  @override
  bool operator ==(Object other) {
    // Compares the args of two [PageRouteInfo] instances using their [ValueKey]s.
    // This is used to check if a route with different args was pushed.
    bool routeArgsEquality(PageRouteInfo route1, PageRouteInfo route2) {
      return switch ((route1._argsValueKey, route2._argsValueKey)) {
        (ValueKey key1, ValueKey key2) => key1 == key2,
        (ValueKey _, dynamic _) || (dynamic _, ValueKey _) => false,
        _ => true,
      };
    }

    return identical(this, other) ||
        other is PageRouteInfo &&
            _name == other._name &&
            fragment == other.fragment &&
            const ListEquality()
                .equals(initialChildren, other.initialChildren) &&
            const MapEquality().equals(rawPathParams, other.rawPathParams) &&
            const MapEquality().equals(rawQueryParams, other.rawQueryParams) &&
            routeArgsEquality(this, other);
  }

  @override
  int get hashCode =>
      _name.hashCode ^
      fragment.hashCode ^
      const MapEquality().hash(rawPathParams) ^
      const MapEquality().hash(rawQueryParams) ^
      const ListEquality().hash(initialChildren) ^
      (_argsValueKey?.hashCode ?? 0);

  /// If the args of this route have a `ValueKey`, returns it.
  ValueKey? get _argsValueKey {
    return switch (args) {
      BaseRouteArgs args => switch (args.key) {
          ValueKey key => key,
          _ => null,
        },
      _ => null,
    };
  }
}

/// A proxy Route page that provides a way to create a [PageRouteInfo]
/// without the need for creating a new Page Widget
class EmptyShellRoute extends PageInfo {
  /// Default constructor
  const EmptyShellRoute(super.name) : super.emptyShell();

  /// Creates a new instance with of [PageRouteInfo]
  PageRouteInfo call({List<PageRouteInfo>? children}) {
    return PageRouteInfo(name, initialChildren: children);
  }

  /// Creates a new instance with of [PageInfo] with an empty shell builder
  /// that returns an [AutoRouter] widget
  PageInfo get page => this;
}

/// A base class for route arguments
abstract class BaseRouteArgs {
  /// Default constructor
  const BaseRouteArgs({this.key});

  /// A key which is used when comparing two routes
  final Key? key;
}
