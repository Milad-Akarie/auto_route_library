import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

class RouteMatcher {
  final Uri _uri;
  RouteSettings _settings;

  RouteMatcher(this._settings) : _uri = Uri.parse(_settings.name);

  bool hasFullMatch(String template) {
    return match(template, fullMatch: true) != null;
  }

  MatchResult match(String template, {bool fullMatch = false}) {
    var pathPattern = _buildPathPattern(template);
    var finalPattern = fullMatch ? '$pathPattern\$' : pathPattern;
    var match = RegExp(finalPattern).stringMatch(_uri.path);
    MatchResult matchResult;
    if (match != null) {
      matchResult = MatchResult(_settings.copyWith(name: match),
          uri: _uri,
          template: template,
          pattern: pathPattern,
          rest: _uri.path.substring(match.length),
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
    return '^${template.replaceAllMapped(RegExp(r':([^/]+)'), (m) => '(?<${m.group(1)}>[^/]+)')}';
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
}

@immutable
class MatchResult {
  final Uri uri;
  final String template;
  final Pattern pattern;
  final String rest;
  final RouteSettings settings;
  final Map<String, String> pathParamsMap;

  MatchResult(
    this.settings, {
    this.uri,
    this.template,
    this.pattern,
    this.rest,
    this.pathParamsMap,
  });

  String get path => settings.name;

  MatchResult prefixPathWith(String parentPath) {
    return MatchResult(
      this.settings,
      uri: this.uri.replace(path: '$parentPath${uri.path}'),
      template: this.template,
      pattern: this.pattern,
      rest: this.rest,
      pathParamsMap: this.pathParamsMap,
    );
  }

  Parameters get queryParams => Parameters(uri.queryParameters);

  Parameters get pathParams => Parameters(pathParamsMap);
}
