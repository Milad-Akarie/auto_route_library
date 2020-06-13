import 'package:auto_route/src/route_matcher.dart';
import 'package:flutter/material.dart';

import '../auto_route.dart';

part 'parameters.dart';

@immutable
class RouteData extends RouteSettings {
  RouteData(this._routeMatch)
      : _pathParams = _routeMatch.pathParams,
        _queryParams = _routeMatch.queryParams,
        super(name: _routeMatch.name, arguments: _routeMatch.arguments);

  final MatchResult _routeMatch;
  final Parameters _pathParams;
  final Parameters _queryParams;

  String get template => _routeMatch.template;

  Parameters get queryParams => _queryParams;

  Parameters get pathParams => _pathParams;

  Object get initialArgsToPass => _routeMatch.initialArgsToPass;

  T getArgs<T>({bool nullOk = true,T Function() orElse}) {
    if(nullOk == true){
      assert(orElse != null);
    }
    if (_hasInvalidArgs<T>(nullOk)) {
      throw FlutterError('Expected ${T.toString()} got ${arguments?.runtimeType ?? 'null'}');
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
        'path: ${_routeMatch.path}, fullName: ${_routeMatch.name}, arguments: $arguments,  pathParams: $_pathParams, queryParams: $_queryParams}';
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
class ParentRouteSettings extends RouteSettings {
  final String initialRoute;
  final String template;

  ParentRouteSettings({
    @required this.template,
    @required String path,
    this.initialRoute,
    Object args,
  }) : super(name: path, arguments: args);
}

@immutable
class ParentRouteData extends RouteData {
  final String initialRoute;
  final RouterBase router;

  ParentRouteData({
    this.initialRoute,
    this.router,
    MatchResult matchResult,
  }) : super(matchResult);

  @override
  String toString() {
    return 'ParentRouteData{template: ${_routeMatch.template}, '
        'path: ${_routeMatch.path}, fullName: ${_routeMatch.name}, arguments: $arguments,  pathParams: $_pathParams, queryParams: $_queryParams}, initialRoute: $initialRoute, router: $router';
  }

  static ParentRouteData of(BuildContext context) {
    var modal = ModalRoute.of(context);
    if (modal != null && modal?.settings is ParentRouteData) {
      return modal.settings as ParentRouteData;
    } else {
      return null;
    }
  }
}
