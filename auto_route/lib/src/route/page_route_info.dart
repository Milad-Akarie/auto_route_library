import 'package:auto_route/src/matcher/route_matcher.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

import '../utils.dart';

@immutable
class PageRouteInfo {
  final String _key;
  final String path;
  final String _rawPathName;
  final Map<String, dynamic> pathParams;
  final Map<String, dynamic> queryParams;
  final String fragment;
  final List<PageRouteInfo> children;
  final Object args;

  const PageRouteInfo(
    this._key, {
    @required this.path,
    String pathName,
    this.children,
    this.queryParams,
    this.pathParams,
    this.fragment,
    this.args,
  }) : _rawPathName = pathName;

  String get routeKey => _key;

  factory PageRouteInfo.fromMatch(RouteMatch match) {
    assert(match != null);
    var children;
    if (match.hasChildren) {
      children = match.children
          .map(
            (m) => PageRouteInfo.fromMatch(m),
          )
          .toList(growable: false);
    }
    return PageRouteInfo(
      match.key,
      path: match.path,
      pathName: match.pathName,
      pathParams: match.pathParams,
      fragment: match.fragment,
      queryParams: match.queryParams,
      children: children,
    );
  }

  String get pathName => p.normalize(_rawPathName ?? _expand(path, pathParams));

  String get fullPathName => p.joinAll([path, if (hasChildren) children.last.fullPathName]);

  bool get hasChildren => !listNullOrEmpty(children);

  static String _expand(String template, Map<String, dynamic> params) {
    if (mapNullOrEmpty(params)) {
      return template;
    }
    var paramsRegex = RegExp(":(${params.keys.join('|')})[?]?");
    var path = template.replaceAllMapped(paramsRegex, (match) {
      return params[match.group(1)]?.toString() ?? '';
    });
    return path;
  }

  PageRouteInfo copyWith({
    String key,
    String path,
    Map<String, dynamic> pathParams,
    Map<String, dynamic> queryParams,
    String fragment,
    List<PageRouteInfo> children,
    Object args,
  }) {
    if ((key == null || identical(key, this.path)) &&
        (path == null || identical(path, this._rawPathName)) &&
        (pathParams == null || identical(pathParams, this.pathParams)) &&
        (queryParams == null || identical(queryParams, this.queryParams)) &&
        (fragment == null || identical(fragment, this.fragment)) &&
        (children == null || identical(children, this.children)) &&
        (args == null || identical(args, this.args))) {
      return this;
    }

    return new PageRouteInfo(
      key ?? this.path,
      pathName: pathName ?? this.pathName,
      pathParams: pathParams ?? this.pathParams,
      queryParams: queryParams ?? this.queryParams,
      fragment: fragment ?? this.fragment,
      children: children ?? this.children,
      args: args ?? this.args,
    );
  }

  @override
  String toString() {
    return 'route{path: $path, template: $path, pathParams: $pathParams}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PageRouteInfo && runtimeType == other.runtimeType && path == other.path;

  @override
  int get hashCode => path.hashCode;
}
