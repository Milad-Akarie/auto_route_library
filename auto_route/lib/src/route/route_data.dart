import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

import 'route_data_scope.dart';

class RouteData {
  final PageRouteInfo route;
  final RouteData? parent;
  final RouteConfig? config;
  final ValueKey<String> key;
  final List<PageRouteInfo<dynamic>> activeSegments;
  final RoutingController? router;

  RouteData({
    required this.route,
    this.parent,
    this.config,
    this.router,
    required this.key,
    List<PageRouteInfo>? initialSegments,
    List<PageRouteInfo<dynamic>>? preMatchedPendingRoutes,
  })  : _preMatchedPendingRoutes = preMatchedPendingRoutes,
        activeSegments = initialSegments ?? <PageRouteInfo<dynamic>>[];

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

  RouteData copyWith({
    PageRouteInfo? route,
    RouteData? parent,
    RouteConfig? config,
    ValueKey<String>? key,
    RouteData? activeChild,
    RoutingController? router,
    List<PageRouteInfo<dynamic>>? preMatchedPendingRoutes,
    List<PageRouteInfo<dynamic>>? activeSegments,
  }) {
    return RouteData(
      route: route ?? this.route,
      parent: parent ?? this.parent,
      router: router ?? this.router,
      config: config ?? this.config,
      key: key ?? this.key,
      initialSegments: activeSegments ?? this.activeSegments,
      preMatchedPendingRoutes: preMatchedPendingRoutes ?? this._preMatchedPendingRoutes,
    );
  }

  void updateActiveSegments(List<PageRouteInfo<dynamic>> currentSegments) {
    activeSegments.clear();
    activeSegments.addAll(currentSegments);
  }
}
