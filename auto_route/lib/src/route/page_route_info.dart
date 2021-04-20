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
  final RouteMatch? match;
  final Map<String, dynamic> params;
  final Map<String, dynamic> queryParams;
  final List<PageRouteInfo>? children;

  const PageRouteInfo(
    this._name, {
    required this.path,
    this.children,
    this.match,
    this.args,
    this.params = const {},
    this.queryParams = const {},
  });

  String get routeName => _name;

  String get stringMatch {
    if (match != null) {
      return p.joinAll(match!.segments);
    }
    return _expand(path, params);
  }

  String get fullPath => p.joinAll([stringMatch, if (hasChildren) children!.last.fullPath]);

  bool get hasChildren => children?.isNotEmpty == true;

  bool get fromRedirect => match?.fromRedirect == true;

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

  PageRouteInfo copyWith({
    String? name,
    String? path,
    T? args,
    RouteMatch? match,
    Map<String, dynamic>? params,
    Map<String, dynamic>? queryParams,
    List<PageRouteInfo>? initialChildren,
  }) {
    if ((name == null || identical(name, this._name)) &&
        (path == null || identical(path, this.path)) &&
        (args == null || identical(args, this.args)) &&
        (match == null || identical(match, this.match)) &&
        (params == null || identical(params, this.params)) &&
        (queryParams == null || identical(queryParams, this.queryParams)) &&
        (initialChildren == null || identical(initialChildren, this.children))) {
      return this;
    }

    return PageRouteInfo(
      name ?? this._name,
      path: path ?? this.path,
      args: args ?? this.args,
      match: match ?? this.match,
      params: params ?? this.params,
      queryParams: queryParams ?? this.queryParams,
      children: initialChildren ?? this.children,
    );
  }

  String toString() {
    return 'Route{name: $_name, path: $path, params: $params}, children: ${children?.map((e) => e.routeName)}';
  }

  PageRouteInfo.fromMatch(RouteMatch match)
      : args = null,
        this.match = match,
        _name = match.config.name,
        path = match.config.path,
        params = match.pathParams.rawMap,
        queryParams = match.queryParams.rawMap,
        children = match.children?.map((m) => PageRouteInfo.fromMatch(m)).toList();

// maybe?
  Future<void> show(BuildContext context) {
    return context.router.push(this);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageRouteInfo &&
          runtimeType == other.runtimeType &&
          _name == other._name &&
          path == other.path &&
          ListEquality().equals(children, other.children) &&
          MapEquality().equals(params, other.params) &&
          MapEquality().equals(queryParams, other.queryParams);

  @override
  int get hashCode =>
      _name.hashCode ^
      path.hashCode ^
      MapEquality().hash(params) ^
      MapEquality().hash(queryParams) ^
      ListEquality().hash(children);
}
