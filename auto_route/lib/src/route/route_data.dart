part of '../router/controller/routing_controller.dart';

class RouteData extends ChangeNotifier {
  RouteMatch _route;
  final RouteData? parent;
  LocalKey get key => _route.key;

  RouteData({
    required RouteMatch route,
    this.parent,
    List<RouteMatch>? preMatchedPendingRoutes,
  })  : _route = route,
        _preMatchedPendingRoutes = preMatchedPendingRoutes;

  List<RouteMatch> get breadcrumbs => List.unmodifiable([
        if (parent != null) ...parent!.breadcrumbs,
        _route,
      ]);

  List<RouteMatch>? _preMatchedPendingRoutes;

  List<RouteMatch>? get preMatchedPendingRoutes {
    final pending = _preMatchedPendingRoutes;
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
        throw FlutterError('${T.toString()} can not be null because it has a required parameter');
      } else {
        return orElse();
      }
    } else if (args is! T) {
      throw FlutterError('Expected [${T.toString()}],  found [${args.runtimeType}]');
    } else {
      return args as T;
    }
  }

  void _updateRoute(RouteMatch value) {
    if (_route != value) {
      _route = value;
      notifyListeners();
    }
  }

  RouteMatch get route => _route;

  String get name => _route.routeName;

  String get path => _route.path;

  Object? get args => _route.args;

  String get match => _route.stringMatch;

  Parameters get pathParams => _route.pathParams;

  Parameters get queryParams => _route.queryParams;

  String get fragment => _route.fragment;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RouteData && runtimeType == other.runtimeType && route == other.route;

  @override
  int get hashCode => route.hashCode ^ parent.hashCode;
}
