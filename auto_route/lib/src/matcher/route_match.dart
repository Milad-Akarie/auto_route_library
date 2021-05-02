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
  final String stringMatch;

  const RouteMatch({
    required this.routeName,
    required this.segments,
    required this.path,
    required this.stringMatch,
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
    String? stringMatch,
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
      stringMatch: stringMatch ?? this.stringMatch,
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
          stringMatch == other.stringMatch &&
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
      ListEquality().hash(children) ^
      fragment.hashCode ^
      redirectedFrom.hashCode ^
      path.hashCode ^
      stringMatch.hashCode ^
      routeName.hashCode ^
      ListEquality().hash(segments);

  @override
  String toString() {
    return 'RouteMatch{routeName: $routeName pathParams: $pathParams, queryParams: $queryParams, children: $children, fragment: $fragment, segments: $segments, redirectedFrom: $redirectedFrom}';
  }

  factory RouteMatch.fromRoute(PageRouteInfo route) {
    final children = <RouteMatch>[];
    if (route.hasChildren) {
      children.addAll(route.initialChildren!.map((e) => RouteMatch.fromRoute(e)));
    }
    return RouteMatch(
      routeName: route.routeName,
      segments: route.stringMatch.split('/'),
      path: route.path,
      stringMatch: route.stringMatch,
      fragment: route.fragment,
      redirectedFrom: route.redirectedFrom,
      children: children,
      pathParams: Parameters(route.rawPathParams),
      queryParams: Parameters(route.rawQueryParams),
    );
  }
}
