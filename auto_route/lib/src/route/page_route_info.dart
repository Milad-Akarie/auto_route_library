import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

import '../../auto_route.dart';
import '../utils.dart';

@optionalTypeArgs
@immutable
class PageRouteInfo<T> {
  final String _name;
  final String path;
  final T? args;
  final Map<String, dynamic> rawPathParams;
  final Map<String, dynamic> rawQueryParams;
  final List<PageRouteInfo>? initialChildren;
  final String fragment;
  final String? _stringMatch;
  final String? redirectedFrom;

  const PageRouteInfo(
    this._name, {
    required this.path,
    this.initialChildren,
    this.args,
    this.rawPathParams = const {},
    this.rawQueryParams = const {},
    this.fragment = '',
    String? stringMatch,
    this.redirectedFrom,
  }) : _stringMatch = stringMatch;

  String get routeName => _name;

  String get stringMatch {
    if (_stringMatch != null) {
      return _stringMatch!;
    }
    return expandPath(path, rawPathParams);
  }

  String get fullPath =>
      p.joinAll([stringMatch, if (hasChildren) initialChildren!.last.fullPath]);

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
        (path == null || identical(path, this.path)) &&
        (fragment == null || identical(fragment, this.fragment)) &&
        (args == null || identical(args, this.args)) &&
        (params == null || identical(params, rawPathParams)) &&
        (queryParams == null || identical(queryParams, rawQueryParams)) &&
        (children == null || identical(children, initialChildren))) {
      return this;
    }

    return PageRouteInfo(
      name ?? _name,
      path: path ?? this.path,
      args: args ?? this.args,
      rawPathParams: params ?? rawPathParams,
      rawQueryParams: queryParams ?? rawQueryParams,
      initialChildren: children ?? initialChildren,
    );
  }

  @override
  String toString() {
    return 'Route{name: $_name, path: $path, params: $rawPathParams}, children: ${initialChildren?.map((e) => e.routeName)}';
  }

  factory PageRouteInfo.fromMatch(RouteMatch match) {
    return PageRouteInfo(
      match.name,
      path: match.path,
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageRouteInfo &&
          _name == other._name &&
          path == other.path &&
          fragment == other.fragment &&
          const ListEquality().equals(initialChildren, other.initialChildren) &&
          const MapEquality().equals(rawPathParams, other.rawPathParams) &&
          const MapEquality().equals(rawQueryParams, other.rawQueryParams);

  @override
  int get hashCode =>
      _name.hashCode ^
      path.hashCode ^
      fragment.hashCode ^
      const MapEquality().hash(rawPathParams) ^
      const MapEquality().hash(rawQueryParams) ^
      const ListEquality().hash(initialChildren);
}
