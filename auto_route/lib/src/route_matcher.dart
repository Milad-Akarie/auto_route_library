import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

class RouteMatcher {
  final Uri _uri;
  final RouteSettings _settings;

  RouteMatcher(this._settings) : _uri = Uri.parse(_settings.name);

  RouteMatcher.fromUri(this._uri) : _settings = null;

  RouteMatch match(RouteDef route, {bool fullMatch = false}) {
    var pattern = fullMatch ? '${route.pattern}\$' : route.pattern;
    var match = RegExp(pattern).stringMatch(_uri.path);
    RouteMatch matchResult;
    if (match != null) {
      var segmentUri = _uri.replace(path: match);
      var rest = _uri.replace(path: _uri.path.substring(match.length));
      matchResult = RouteMatch(
          name: rest.pathSegments.isNotEmpty ? segmentUri.path : segmentUri.toString(),
          arguments: _settings?.arguments,
          uri: segmentUri,
          routeDef: route,
          rest: rest,
          pathParamsMap: _extractPathParams(route.pattern, match));
    }
    return matchResult;
  }

  Map<String, String> _extractPathParams(String pathPattern, String path) {
    var pathMatch = RegExp(pathPattern).firstMatch(path);
    var params = <String, String>{};
    if (pathMatch != null) {
      for (var name in pathMatch.groupNames) {
        params[name] = pathMatch.namedGroup(name);
      }
    }
    return params;
  }
}

@immutable
class RouteMatch extends RouteSettings {
  final Uri uri;
  final RouteDef routeDef;
  final Uri rest;
  final Map<String, String> pathParamsMap;
  final Object initialArgsToPass;

  RouteMatch({
    @required this.uri,
    @required this.routeDef,
    @required this.rest,
    @required this.pathParamsMap,
    this.initialArgsToPass,
    @required String name,
    @required Object arguments,
  }) : super(name: name, arguments: arguments);

  bool get hasRest => rest?.pathSegments?.isNotEmpty == true;

  bool get hasGuards => routeDef.guards?.isNotEmpty == true;

  bool get isParent => routeDef.innerRouter != null;

  String get template => routeDef.template;

  String get restAsString => rest.pathSegments.isEmpty ? null : rest.toString();

  String get path => uri.path;

  Parameters get queryParams => Parameters(uri.queryParameters);

  Parameters get pathParams => Parameters(pathParamsMap);

  @override
  RouteSettings copyWith({
    String name,
    Object arguments,
    Object initialArgsToPass,
  }) {
    return RouteMatch(
        name: name ?? this.name,
        arguments: arguments ?? this.arguments,
        initialArgsToPass: initialArgsToPass ?? this.initialArgsToPass,
        uri: this.uri,
        routeDef: this.routeDef,
        rest: this.rest,
        pathParamsMap: this.pathParamsMap);
  }
}
