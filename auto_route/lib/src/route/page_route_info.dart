import 'package:auto_route/src/matcher/route_match.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

import '../../auto_route.dart';
import '../utils.dart';

@immutable
class PageRouteInfo {
  final String _key;
  final String path;
  final String _rawMatch;
  final Map<String, dynamic> pathParams;
  final Map<String, dynamic> queryParams;
  final String fragment;
  final List<PageRouteInfo> children;
  final RouteArgs args;

  const PageRouteInfo(
    this._key, {
    @required this.path,
    String match,
    this.children,
    this.queryParams,
    this.pathParams,
    this.fragment,
    this.args,
  }) : _rawMatch = match;

  String get routeKey => _key;

  factory PageRouteInfo.fromMatch(RouteMatch match) {
    assert(match != null);
    var children;
    if (match.hasChildren) {
      children = match.children.map((m) => PageRouteInfo.fromMatch(m)).toList(growable: false);
    }
    return PageRouteInfo(
      match.config.key,
      path: match.config.path,
      match: p.joinAll(match.segments),
      pathParams: match.pathParams,
      fragment: match.fragment,
      queryParams: match.queryParams,
      children: children,
    );
  }

  String get match => _rawMatch ?? _expand(path, pathParams);

  String get fullPath => p.joinAll([match, if (hasChildren) children.last.fullPath]);

  bool get hasChildren => !listNullOrEmpty(children);

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
    String key,
    String path,
    Map<String, dynamic> pathParams,
    Map<String, dynamic> queryParams,
    String fragment,
    List<PageRouteInfo> children,
    Object args,
  }) {
    if ((key == null || identical(key, this.path)) &&
        (path == null || identical(path, this._rawMatch)) &&
        (pathParams == null || identical(pathParams, this.pathParams)) &&
        (queryParams == null || identical(queryParams, this.queryParams)) &&
        (fragment == null || identical(fragment, this.fragment)) &&
        (children == null || identical(children, this.children)) &&
        (args == null || identical(args, this.args))) {
      return this;
    }

    return new PageRouteInfo(
      key ?? this._key,
      path: path ?? this.path,
      match: match ?? this.match,
      pathParams: pathParams ?? this.pathParams,
      queryParams: queryParams ?? this.queryParams,
      fragment: fragment ?? this.fragment,
      children: children ?? this.children,
      args: args ?? this.args,
    );
  }

  @override
  String toString() {
    return 'route{path: $path, pathName: $path, pathParams: $pathParams}';
  }

  @override
  bool operator ==(Object o) {
    var mapEquality = MapEquality();
    return identical(this, o) ||
        o is PageRouteInfo &&
            runtimeType == o.runtimeType &&
            _key == o._key &&
            path == o.path &&
            _rawMatch == o._rawMatch &&
            fragment == o.fragment &&
            args == o.args &&
            mapEquality.equals(pathParams, o.pathParams) &&
            mapEquality.equals(queryParams, o.queryParams) &&
            ListEquality().equals(children, o.children);
  }

// maybe?
  Future<void> push(BuildContext context) {
    return context.router.push(this);
  }

  @override
  int get hashCode =>
      _key.hashCode ^
      path.hashCode ^
      _rawMatch.hashCode ^
      pathParams.hashCode ^
      queryParams.hashCode ^
      fragment.hashCode ^
      children.hashCode ^
      args.hashCode;
}
