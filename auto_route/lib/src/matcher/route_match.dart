import 'package:collection/collection.dart';

import '../../auto_route.dart';

class RouteMatch {
  final Parameters pathParams;
  final Parameters queryParams;
  final List<RouteMatch>? children;
  final String fragment;
  final List<String> segments;
  final String? redirectedFrom;
  final String routeName;
  final String path;

  const RouteMatch({
    required this.routeName,
    required this.segments,
    required this.path,
    this.children,
    this.pathParams = const Parameters({}),
    this.queryParams = const Parameters({}),
    this.fragment = '',
    this.redirectedFrom,
  });

  bool get hasChildren => children?.isNotEmpty == true;

  bool get fromRedirect => redirectedFrom != null;

  List<String> get allSegments => [...segments, if (hasChildren) ...children!.last.allSegments];

  RouteMatch copyWith({
    String? key,
    String? path,
    RouteConfig? def,
    Parameters? pathParams,
    Parameters? queryParams,
    List<RouteMatch>? children,
    String? fragment,
    List<String>? segments,
    String? redirectedFrom,
    String? routeName,
  }) {
    return RouteMatch(
      path: path ?? this.path,
      routeName: routeName ?? this.routeName,
      segments: segments ?? this.segments,
      children: children ?? this.children,
      pathParams: pathParams ?? this.pathParams,
      queryParams: queryParams ?? this.queryParams,
      fragment: fragment ?? this.fragment,
      redirectedFrom: redirectedFrom ?? this.redirectedFrom,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteMatch &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          routeName == other.routeName &&
          pathParams == other.pathParams &&
          queryParams == other.queryParams &&
          ListEquality().equals(children, other.children) &&
          fragment == other.fragment &&
          redirectedFrom == other.redirectedFrom &&
          ListEquality().equals(segments, other.segments);

  @override
  int get hashCode =>
      pathParams.hashCode ^
      queryParams.hashCode ^
      children.hashCode ^
      fragment.hashCode ^
      redirectedFrom.hashCode ^
      path.hashCode ^
      routeName.hashCode ^
      segments.hashCode;

  @override
  String toString() {
    return 'RouteMatch{routeName: $routeName pathParams: $pathParams, queryParams: $queryParams, children: $children, fragment: $fragment, segments: $segments, redirectedFrom: $redirectedFrom}';
  }

  factory RouteMatch.fromRoute(PageRouteInfo route) {
    final children = <RouteMatch>[];
    if (route.hasChildren) {
      children.addAll(route.children!.map((e) => RouteMatch.fromRoute(e)));
    }
    return RouteMatch(
      routeName: route.routeName,
      segments: route.stringMatch.split('/'),
      path: route.path,
      fragment: route.fragment,
      redirectedFrom: route.redirectedFrom,
      children: children,
      pathParams: Parameters(route.params),
      queryParams: Parameters(route.queryParams),
    );
  }
}
