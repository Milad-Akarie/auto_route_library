part of '../router/controller/routing_controller.dart';

class RouteData {
  RouteMatch _route;
  RouteData? _parent;
  final RoutingController router;

  LocalKey get key => _route.key;

  RouteData({
    required RouteMatch route,
    required this.router,
    RouteData? parent,
    required this.pendingChildren,
  })  : _route = route,
        _parent = parent;

  List<RouteMatch> get breadcrumbs => List.unmodifiable([
        if (_parent != null) ..._parent!.breadcrumbs,
        _route,
      ]);

  final List<RouteMatch> pendingChildren;

  bool get isActive => router.isRouteActive(name);

  bool get hasPendingChildren => pendingChildren.isNotEmpty;

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
      return args as T;
    }
  }

  void _updateRoute(RouteMatch value) {
    if (_route != value) {
      _route = value;
    }
  }

  void _updateParentData(RouteData value) {
    _parent = value;
  }

  RouteMatch get route => _route;

  String get name => _route.name;

  String get path => _route.path;

  Object? get args => _route.args;

  String get match => _route.stringMatch;

  Parameters get inheritedPathParams {
    if (_parent == null) {
      return const Parameters(const {});
    }
    return _parent!.breadcrumbs.map((e) => e.pathParams).reduce(
          (value, element) => value + element,
        );
  }

  Parameters get pathParams => _route.pathParams;

  Parameters get queryParams => _route.queryParams;

  String get fragment => _route.fragment;

  RouteMatch _getTopMatch(RouteMatch routeMatch) {
    if (routeMatch.hasChildren) {
      return _getTopMatch(routeMatch.children!.last);
    } else {
      return routeMatch;
    }
  }

  RouteMatch get topMatch {
    if (hasPendingChildren) {
      return _getTopMatch(pendingChildren.last);
    }

    return _route;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteData &&
          runtimeType == other.runtimeType &&
          route == other.route;

  @override
  int get hashCode => route.hashCode;
}
