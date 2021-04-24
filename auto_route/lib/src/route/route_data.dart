import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

import 'route_data_scope.dart';

class RouteData {
  final PageRouteInfo route;
  final RouteData? parent;
  final RouteConfig? config;
  final ValueKey<String> key;
  final List<PageRouteInfo> activeSegments;
  RouteData? activeChild;

  RouteData({
    required this.route,
    this.parent,
    this.config,
    required this.key,
    this.activeChild,
    this.activeSegments = const [],
    List<PageRouteInfo<dynamic>>? preMatchedPendingRoutes,
  }) : _preMatchedPendingRoutes = preMatchedPendingRoutes;

  List<PageRouteInfo> get breadcrumbs => List.unmodifiable([
        if (parent != null) ...parent!.breadcrumbs,
        route,
      ]);

  List<PageRouteInfo<dynamic>>? _preMatchedPendingRoutes;

  List<PageRouteInfo<dynamic>>? get preMatchedPendingRoutes {
    var pending = _preMatchedPendingRoutes;
    _preMatchedPendingRoutes = null;
    return pending;
  }

  bool get hasPendingRoutes => _preMatchedPendingRoutes != null;

  static RouteData of(BuildContext context) {
    return RouteDataScope.of(context);
  }

  T argsAs<T>({T Function()? orElse}) {
    final args = route.args;
    if (args == null) {
      if (orElse == null) {
        throw FlutterError('${T.toString()} can not be null because it has a required parameter');
      } else {
        return orElse();
      }
    } else if (args is! T) {
      throw FlutterError('Expected [${T.toString()}],  found [${args.runtimeType}]');
    } else {
      return args;
    }
  }

  String get name => route.routeName;

  String get path => route.path;

  String get match => route.stringMatch;

  String get fullSegment => [route, ...activeSegments].map((e) => e.stringMatch).join('/');

  Parameters get pathParams => Parameters(route.params);

  Parameters get queryParams => Parameters(route.queryParams);

  String? get fragment => route.fragment;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteData && runtimeType == other.runtimeType && activeChild == other.activeChild;

  @override
  int get hashCode => activeChild.hashCode;

  RouteData copyWith({
    PageRouteInfo? route,
    RouteData? parent,
    RouteConfig? config,
    ValueKey<String>? key,
    RouteData? activeChild,
    List<PageRouteInfo<dynamic>>? preMatchedPendingRoutes,
    List<PageRouteInfo<dynamic>>? activeSegments,
  }) {
    return RouteData(
      route: route ?? this.route,
      parent: parent ?? this.parent,
      config: config ?? this.config,
      key: key ?? this.key,
      activeChild: activeChild,
      activeSegments: activeSegments ?? this.activeSegments,
      preMatchedPendingRoutes: preMatchedPendingRoutes ?? this._preMatchedPendingRoutes,
    );
  }
}
