import 'package:auto_route/src/matcher/route_match.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

import '../../auto_route.dart';
import '../utils.dart';

@optionalTypeArgs
class PageRouteInfo<T> {
  final String _name;
  final String path;
  final T? args;
  final Map<String, dynamic> params;
  final Map<String, dynamic> queryParams;
  final List<PageRouteInfo>? children;
  final String fragment;
  final String? _stringMatch;
  final String? redirectedFrom;

  const PageRouteInfo(
    this._name, {
    required this.path,
    this.children,
    this.args,
    this.params = const {},
    this.queryParams = const {},
    this.fragment = '',
    String? stringMatch,
    this.redirectedFrom,
  }) : _stringMatch = stringMatch;

  String get routeName => _name;

  String get stringMatch {
    if (_stringMatch != null) {
      return _stringMatch!;
    }
    return _expand(path, params);
  }

  String get fullPath => p.joinAll([stringMatch, if (hasChildren) children!.last.fullPath]);

  bool get hasChildren => children?.isNotEmpty == true;

  bool get fromRedirect => redirectedFrom != null;

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
    return [this, if (hasChildren) ...children!.last.flattened];
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
        (params == null || identical(params, this.params)) &&
        (queryParams == null || identical(queryParams, this.queryParams)) &&
        (children == null || identical(children, this.children))) {
      return this;
    }

    return PageRouteInfo(
      name ?? this._name,
      path: path ?? this.path,
      args: args ?? this.args,
      params: params ?? this.params,
      queryParams: queryParams ?? this.queryParams,
      children: children ?? this.children,
    );
  }

  String toString() {
    return 'Route{name: $_name, path: $path, params: $params}, children: ${children?.map((e) => e.routeName)}';
  }

  factory PageRouteInfo.fromMatch(RouteMatch match) {
    return PageRouteInfo(
      match.routeName,
      path: match.path,
      params: match.pathParams.rawMap,
      queryParams: match.queryParams.rawMap,
      fragment: match.fragment,
      redirectedFrom: match.redirectedFrom,
      stringMatch: p.joinAll(match.segments),
      children: match.children?.map((m) => PageRouteInfo.fromMatch(m)).toList(),
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
          ListEquality().equals(children, other.children) &&
          MapEquality().equals(params, other.params) &&
          MapEquality().equals(queryParams, other.queryParams);

  @override
  int get hashCode =>
      _name.hashCode ^
      path.hashCode ^
      fragment.hashCode ^
      MapEquality().hash(params) ^
      MapEquality().hash(queryParams) ^
      ListEquality().hash(children);
}
