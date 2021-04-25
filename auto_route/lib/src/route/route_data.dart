part of '../router/controller/routing_controller.dart';

class RouteData {
  PageRouteInfo _route;
  final RouteData? parent;
  final RouteConfig? config;
  final ValueKey<String> key;

  RouteData({
    required PageRouteInfo route,
    this.parent,
    this.config,
    required this.key,
    List<PageRouteInfo<dynamic>>? preMatchedPendingRoutes,
  })  : _route = route,
        _preMatchedPendingRoutes = preMatchedPendingRoutes;

  List<PageRouteInfo> get breadcrumbs => List.unmodifiable([
        if (parent != null) ...parent!.breadcrumbs,
        _route,
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
    final args = _route.args;
    if (args == null) {
      if (orElse == null) {
        throw FlutterError(
            '${T.toString()} can not be null because it has a required parameter');
      } else {
        return orElse();
      }
    } else if (args is! T) {
      throw FlutterError(
          'Expected [${T.toString()}],  found [${args.runtimeType}]');
    } else {
      return args;
    }
  }

  PageRouteInfo get route => _route;
  String get name => _route.routeName;

  String get path => _route.path;

  String get match => _route.stringMatch;

  Parameters get pathParams => Parameters(_route.params);

  Parameters get queryParams => Parameters(_route.queryParams);

  String? get fragment => _route.fragment;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteData &&
          runtimeType == other.runtimeType &&
          route == other.route;

  @override
  int get hashCode => route.hashCode;

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
      config: config ?? this.config,
      key: key ?? this.key,
      preMatchedPendingRoutes:
          preMatchedPendingRoutes ?? this._preMatchedPendingRoutes,
    );
  }
}
