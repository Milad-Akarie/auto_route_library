import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import '../../auto_route.dart';
import '../utils.dart';

@optionalTypeArgs
@immutable
class PageRouteInfo<T> {
  final String _name;
  final T? args;
  final Map<String, dynamic> rawPathParams;
  final Map<String, dynamic> rawQueryParams;
  final List<PageRouteInfo>? initialChildren;
  final String fragment;
  final String? redirectedFrom;

  const PageRouteInfo(
    this._name, {
    this.initialChildren,
    this.args,
    this.rawPathParams = const {},
    this.rawQueryParams = const {},
    this.fragment = '',
    String? stringMatch,
    this.redirectedFrom,
  });

  String get routeName => _name;

  bool get hasChildren => initialChildren?.isNotEmpty == true;

  bool get fromRedirect => redirectedFrom != null;

  Parameters get pathParams => Parameters(rawPathParams);

  Parameters get queryParams => Parameters(rawQueryParams);

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

  List<PageRouteInfo> get flattened {
    return [this, if (hasChildren) ...initialChildren!.last.flattened];
  }

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

  Future<E?> show<E>(BuildContext context) {
    return context.router.push<E>(this);
  }

  RouteMatch? match(BuildContext context) {
    return context.router.match(this);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageRouteInfo &&
          _name == other._name &&
          fragment == other.fragment &&
          const ListEquality().equals(initialChildren, other.initialChildren) &&
          const MapEquality().equals(rawPathParams, other.rawPathParams) &&
          const MapEquality().equals(rawQueryParams, other.rawQueryParams);

  @override
  int get hashCode =>
      _name.hashCode ^
      fragment.hashCode ^
      const MapEquality().hash(rawPathParams) ^
      const MapEquality().hash(rawQueryParams) ^
      const ListEquality().hash(initialChildren);
}
