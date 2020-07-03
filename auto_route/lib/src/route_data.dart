part of 'extended_navigator.dart';

@immutable
class RouteData extends RouteSettings {
  RouteData(this._routeMatch)
      : _pathParams = _routeMatch.pathParams,
        _queryParams = _routeMatch.queryParams,
        super(name: _routeMatch.name, arguments: _routeMatch.arguments);

  final RouteMatch _routeMatch;
  final Parameters _pathParams;
  final Parameters _queryParams;

  String get template => _routeMatch.template;

  Parameters get queryParams => _queryParams;

  Parameters get pathParams => _pathParams;

  String get path => _routeMatch.uri.path;

  Object get _initialArgsToPass => _routeMatch.initialArgsToPass;

  T getArgs<T>({bool nullOk = true, T Function() orElse}) {
    if (nullOk == true) {
      assert(orElse != null);
    }
    if (_hasInvalidArgs<T>(nullOk)) {
      throw FlutterError('Expected [${T.toString()}],  found [${arguments?.runtimeType}]');
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
    return 'RouteData{template: ${_routeMatch.template}, '
        'path: ${_routeMatch.template}, fullName: ${_routeMatch.name}, args: $arguments,  params: $_pathParams, query: $_queryParams}';
  }

  static RouteData of(BuildContext context) {
    var modal = ModalRoute.of(context);
    if (modal != null && modal.settings is RouteData) {
      return modal.settings as RouteData;
    } else {
      return null;
    }
  }
}

@immutable
class _ParentRouteData<T extends RouterBase> extends RouteData {
  final String initialRoute;
  final T router;

  _ParentRouteData({
    this.initialRoute,
    this.router,
    RouteMatch matchResult,
  }) : super(matchResult);


  static _ParentRouteData of(BuildContext context) {
    var modal = ModalRoute.of(context);
    if (modal != null && modal?.settings is _ParentRouteData) {
      return modal.settings as _ParentRouteData;
    } else {
      return null;
    }
  }
}
