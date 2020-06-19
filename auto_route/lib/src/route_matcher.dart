import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

class RouteMatcher {
  final Uri _uri;
  final RouteSettings _settings;

  RouteMatcher(this._settings) : _uri = Uri.parse(_settings.name);

  RouteMatcher.fromUri(this._uri) : _settings = null;

  MatchResult match(String template, {bool fullMatch = false}) {
    var pathPattern = _buildPathPattern(template);
    var finalPattern = fullMatch ? '$pathPattern\$' : pathPattern;
    var match = RegExp(finalPattern).stringMatch(_uri.path);
    MatchResult matchResult;
    if (match != null) {
      var segmentUri = _uri.replace(path: match);
      matchResult = MatchResult(
          name: segmentUri.toString(),
          arguments: _settings?.arguments,
          uri: segmentUri,
          template: template,
          pattern: pathPattern,
          rest: _uri.replace(path: _uri.path.substring(match.length)),
          pathParamsMap: _extractPathParams(pathPattern, match));
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

  Pattern _buildPathPattern(String template) {
    return '^${template.replaceAllMapped(RegExp(r':([^/]+)'), (m) {
//      print(m.group(0));
      return '(?<${m.group(1)}>[^/]+)';
    })}';
  }

  List<MatchResult> allMatches(Set<String> templates) {
    var matches = <MatchResult>[];
    for (var template in templates) {
      var matchResult = match(template);
      if (matchResult != null) {
        matches.add(matchResult);
      }
    }
    return matches;
  }

  Set<String> matchingSegments(Set<String> templates) {
    var matches = <String>{};
    for (var template in templates) {
      var match = RegExp(_buildPathPattern(template)).stringMatch(_uri.path);
      if (match != null) {
        matches.add(match);
      }
    }
    return matches;
  }
}

@immutable
class MatchResult extends RouteSettings {
  final Uri uri;
  final String template;
  final Pattern pattern;
  final Uri rest;
  final Map<String, String> pathParamsMap;
  final Object initialArgsToPass;

  MatchResult({
    this.uri,
    this.template,
    this.pattern,
    this.rest,
    this.pathParamsMap,
    this.initialArgsToPass,
    String name,
    Object arguments,
  }) : super(name: name, arguments: arguments);

  bool get hasRest => rest?.pathSegments?.isNotEmpty == true;

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
        template: this.template,
        pattern: this.pattern,
        rest: this.rest,
        pathParamsMap: this.pathParamsMap);
  }

  String get path => uri.path;

  Parameters get queryParams => Parameters(uri.queryParameters);

  Parameters get pathParams => Parameters(pathParamsMap);
}
