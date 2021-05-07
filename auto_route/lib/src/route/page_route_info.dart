import 'package:auto_route/src/matcher/route_match.dart';
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
    return _expand(path, rawPathParams);
  }

  String get fullPath =>
      p.joinAll([stringMatch, if (hasChildren) initialChildren!.last.fullPath]);

  bool get hasChildren => initialChildren?.isNotEmpty == true;

  bool get fromRedirect => redirectedFrom != null;

  Parameters get pathParams => Parameters(rawPathParams);

  Parameters get queryParams => Parameters(rawQueryParams);

  @deprecated
  Map<String, dynamic> get params => rawPathParams;

  static String _expand(String template, Map<String, dynamic> params) {
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
    if ((name == null || identical(name, this._name)) &&
        (path == null || identical(path, this.path)) &&
        (fragment == null || identical(fragment, this.fragment)) &&
        (args == null || identical(args, this.args)) &&
        (params == null || identical(params, this.rawPathParams)) &&
        (queryParams == null || identical(queryParams, this.rawQueryParams)) &&
        (children == null || identical(children, this.initialChildren))) {
      return this;
    }

    return PageRouteInfo(
      name ?? this._name,
      path: path ?? this.path,
      args: args ?? this.args,
      rawPathParams: params ?? this.rawPathParams,
      rawQueryParams: queryParams ?? this.rawQueryParams,
      initialChildren: children ?? this.initialChildren,
    );
  }

  String toString() {
    return 'Route{name: $_name, path: $path, params: $rawPathParams}, children: ${initialChildren?.map((e) => e.routeName)}';
  }

  factory PageRouteInfo.fromMatch(RouteMatch match) {
    return PageRouteInfo(
      match.routeName,
      path: match.path,
      rawPathParams: match.pathParams.rawMap,
      rawQueryParams: match.queryParams.rawMap,
      fragment: match.fragment,
      redirectedFrom: match.redirectedFrom,
      stringMatch: match.stringMatch,
      initialChildren:
          match.children?.map((m) => PageRouteInfo.fromMatch(m)).toList(),
    );
  }

// maybe?
  Future<void> show(BuildContext context) {
    return context.router.push(this);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageRouteInfo &&
          _name == other._name &&
          path == other.path &&
          fragment == other.fragment &&
          ListEquality().equals(initialChildren, other.initialChildren) &&
          MapEquality().equals(rawPathParams, other.rawPathParams) &&
          MapEquality().equals(rawQueryParams, other.rawQueryParams);

  @override
  int get hashCode =>
      _name.hashCode ^
      path.hashCode ^
      fragment.hashCode ^
      MapEquality().hash(rawPathParams) ^
      MapEquality().hash(rawQueryParams) ^
      ListEquality().hash(initialChildren);
}
