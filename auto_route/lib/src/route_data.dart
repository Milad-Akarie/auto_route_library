part of 'extended_navigator.dart';

@immutable
class RouteData extends RouteSettings {
  RouteData(this.routeMatch)
      : _pathParams = routeMatch.pathParams,
        _queryParams = routeMatch.queryParams,
        super(name: routeMatch.name, arguments: routeMatch.arguments);

  final RouteMatch routeMatch;
  final Parameters _pathParams;
  final Parameters _queryParams;

  String get template => routeMatch.template;

  Parameters get queryParams => _queryParams;

  Parameters get pathParams => _pathParams;

  String get path => routeMatch.uri.path;

  Object get _initialArgsToPass => routeMatch.initialArgsToPass;

  T getArgs<T>({bool nullOk = true, T Function() orElse}) {
    if (nullOk == true) {
      assert(orElse != null);
    }
    if (_hasInvalidArgs<T>(nullOk)) {
      throw FlutterError(
          'Expected [${T.toString()}],  found [${arguments?.runtimeType}]');
    }
    return arguments as T ?? orElse();
  }

  bool _hasInvalidArgs<T>(bool nullOk) {
    if (!nullOk) {
      return (arguments is! T);
    } else {
      return (arguments != null && arguments is! T);
    }
  }

  @override
  String toString() {
    return 'RouteData{template: ${routeMatch.template}, '
        'path: ${routeMatch.path}, fullName: ${routeMatch.name}, args: $arguments,  params: $_pathParams, query: $_queryParams}';
  }

  static RouteData of(BuildContext context) {
    var modal = ModalRoute.of(context);
    if (modal != null && modal.settings is RouteData) {
      return modal.settings as RouteData;
    } else {
      return null;
    }
  }

  static RoutePredicate withPath(String path) {
    return (Route<dynamic> route) {
      return !route.willHandlePopInternally &&
          route is ModalRoute &&
          route.settings is RouteData &&
          (route.settings as RouteData).template == path;
    };
  }
}

@immutable
class ParentRouteData<T extends RouteGenerator> extends RouteData {
  final String initialRoute;
  final T routeGenerator;

  ParentRouteData({
    this.initialRoute,
    this.routeGenerator,
    RouteMatch matchResult,
  }) : super(matchResult);

  static ParentRouteData of(BuildContext context) {
    var modal = ModalRoute.of(context);
    if (modal != null && modal?.settings is ParentRouteData) {
      return modal.settings as ParentRouteData;
    } else {
      return null;
    }
  }
}
