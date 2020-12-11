import 'package:meta/meta.dart';

import '../../auto_route.dart';
import '../utils.dart';

@immutable
class RouteMatch {
  final RouteConfig config;
  final Map<String, dynamic> pathParams;
  final Map<String, dynamic> queryParams;
  final List<RouteMatch> children;
  final String fragment;
  final List<String> segments;

  const RouteMatch({
    @required this.config,
    @required this.segments,
    this.children,
    this.pathParams,
    this.queryParams,
    this.fragment,
  });

  bool get hasChildren => !listNullOrEmpty(children);

  RouteMatch copyWith({
    String key,
    String path,
    RouteConfig def,
    Map<String, dynamic> pathParams,
    Map<String, dynamic> queryParams,
    List<RouteMatch> children,
    String fragment,
    List<String> segments,
  }) {
    return RouteMatch(
      config: def ?? this.config,
      segments: segments ?? this.segments,
      children: children ?? this.children,
      pathParams: pathParams ?? this.pathParams,
      queryParams: queryParams ?? this.queryParams,
      fragment: fragment ?? this.fragment,
    );
  }

  toString() {
    return 'RouteMatch{key: ${config.path}, segments: $segments, params: $pathParams children: $children}';
  }
}
