import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

class RouteMatcher {
  final Uri _uri;
  final RouteSettings _settings;

  RouteMatcher(this._settings) : _uri = Uri.parse(_settings.name);

  RouteMatcher.fromUri(this._uri) : _settings = null;

  MatchResult match(RouteDef route, {bool fullMatch = false}) {
    var pattern = fullMatch ? '${route.pattern}\$' : route.pattern;
    var match = RegExp(pattern).stringMatch(_uri.path);
    MatchResult matchResult;
    if (match != null) {
      var segmentUri = _uri.replace(path: match);
      matchResult = MatchResult(
          name: segmentUri.toString(),
          arguments: _settings?.arguments,
          uri: segmentUri,
          routeDef: route,
          rest: _uri.replace(path: _uri.path.substring(match.length)),
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

  List<MatchResult> allMatches(List<RouteDef> routes, [RouterBase router]) {
    var matches = <MatchResult>[];
    for (var route in routes) {
      var matchResult = match(route);
      if (matchResult != null) {
        matches.add(matchResult);
        if (!matchResult.hasRest) {
          break;
        }
      }
    }
    return matches;
  }

//  Set<String> matchingSegments(Set<String> templates) {
//    var matches = <String>{};
//    for (var template in templates) {
//      var match = RegExp(_buildPathPattern(template)).stringMatch(_uri.path);
//      if (match != null) {
//        matches.add(match);
//      }
//    }
//    return matches;
//  }
}

@immutable
class MatchResult extends RouteSettings {
  final Uri uri;
  final RouteDef routeDef;
  final Uri rest;
  final Map<String, String> pathParamsMap;
  final Object initialArgsToPass;

  MatchResult({
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

  bool get isParent => routeDef.router != null;

  String get template => routeDef.template;

  @override
  RouteSettings copyWith({
    String name,
    Object arguments,
    Object initialArgsToPass,
  }) {
    return MatchResult(
        name: name ?? this.name,
        arguments: arguments ?? this.arguments,
        initialArgsToPass: initialArgsToPass ?? this.initialArgsToPass,
        uri: this.uri,
        routeDef: this.routeDef,
        rest: this.rest,
        pathParamsMap: this.pathParamsMap);
  }

  String get path => uri.path;

  Parameters get queryParams => Parameters(uri.queryParameters);

  Parameters get pathParams => Parameters(pathParamsMap);
}
