import 'package:meta/meta.dart';

import '../../auto_route.dart';
import '../utils.dart';

@immutable
class RouteMatch {
  final RouteConfig config;
  final Parameters pathParams;
  final Parameters queryParams;
  final List<RouteMatch> children;
  final String fragment;
  final List<String> segments;
  final Parameters params;

  const RouteMatch({
    @required this.config,
    @required this.segments,
    this.children,
    this.pathParams,
    this.queryParams,
    this.fragment,
  })  : assert(config != null),
        assert(segments != null),
        params = pathParams + queryParams;

  bool get hasChildren => !listNullOrEmpty(children);

  PageRouteInfo get toRoute => config.routeBuilder(this);

  String get path => config.path;

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

  toString() {
    return 'RouteMatch{key: ${config.path}, children: $children}';
  }
}
