part of '../router/controller/routing_controller.dart';

class RouteData {
  RouteMatch _match;
  RouteData? _parent;
  final RoutingController router;

  LocalKey get key => _match.key;

  RouteData({
    required RouteMatch route,
    required this.router,
    RouteData? parent,
    required this.pendingChildren,
  })  : _match = route,
        _parent = parent;

  final List<RouteMatch> pendingChildren;

  bool get isActive => router.isRouteActive(name);

  bool get hasPendingChildren => pendingChildren.isNotEmpty;

  static RouteData of(BuildContext context) {
    return RouteDataScope.of(context).routeData;
  }

  bool get hasPendingSubNavigation =>
      hasPendingChildren && pendingChildren.last.hasChildren;

  T argsAs<T>({T Function()? orElse}) {
    final args = _match.args;
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

  void _updateRoute(RouteMatch value) {
    if (_match != value) {
      _match = value;
    }
  }

  void _updateParentData(RouteData value) {
    _parent = value;
  }

  RouteMatch get route => _match;

  String get name => _match.name;

  String get path => _match.path;

  RouteData? get parent => _parent;

  Map<String, dynamic> get meta => _match.meta;

  Object? get args => _match.args;

  String get match => _match.stringMatch;

  List<RouteMatch> get breadcrumbs => List.unmodifiable([
        if (_parent != null) ..._parent!.breadcrumbs,
        _match,
      ]);

  Parameters get inheritedPathParams {
    final params = breadcrumbs.map((e) => e.pathParams).reduce(
          (value, element) => value + element,
        );
    return params;
  }

  Parameters get pathParams => _match.pathParams;

  Parameters get queryParams => _match.queryParams;

  String get fragment => _match.fragment;

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
    return _match;
  }
}
