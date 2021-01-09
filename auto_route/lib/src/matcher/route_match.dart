import 'package:meta/meta.dart';

import '../../auto_route.dart';
import '../utils.dart';

import 'package:collection/collection.dart';

@immutable
class RouteMatch {
  final RouteConfig config;
  final Parameters pathParams;
  final Parameters queryParams;
  final List<RouteMatch> children;
  final String fragment;
  final List<String> segments;

  const RouteMatch({
    @required this.config,
    @required this.segments,
    this.children,
    this.pathParams = const Parameters({}),
    this.queryParams = const Parameters({}),
    this.fragment = '',
  })  : assert(config != null),
        assert(segments != null);

  bool get hasChildren => !listNullOrEmpty(children);

  PageRouteInfo get toRoute => config.routeBuilder(this);

  String get path => config.path;

  List<String> get url => [...segments, if (hasChildren) ...children.last.url];

  List<PageRouteInfo> buildChildren() {
    return children?.map((m) => m.toRoute)?.toList(growable: false);
  }

  RouteMatch copyWith({
    String key,
    String path,
    RouteConfig def,
    Parameters pathParams,
    Parameters queryParams,
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteMatch &&
          runtimeType == other.runtimeType &&
          config == other.config &&
          pathParams == other.pathParams &&
          queryParams == other.queryParams &&
          ListEquality().equals(children, other.children) &&
          fragment == other.fragment &&
          ListEquality().equals(segments, other.segments);

  @override
  int get hashCode =>
      config.hashCode ^
      pathParams.hashCode ^
      queryParams.hashCode ^
      children.hashCode ^
      fragment.hashCode ^
      segments.hashCode;

  @override
  String toString() {
    return 'RouteMatch{config: $config, pathParams: $pathParams, queryParams: $queryParams, children: $children, fragment: $fragment, segments: $segments}';
  }
}
