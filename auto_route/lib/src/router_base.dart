part of 'extended_navigator.dart';

typedef AutoRouteFactory = Route<dynamic> Function(RouteData data);
typedef RouterBuilder<T extends RouterBase> = T Function();

class RouterBase {
  RouterBase({this.routes});
  final List<RouteDef> routes;

  Set<String> get allRoutes => routes.map((e) => e.template).toSet();

  Route<dynamic> onGenerateRoute(RouteSettings settings, [String basePath]) {
    assert(routes != null);
    assert(settings != null);
    var match = findFullMatch(settings);
    if (match != null) {
      var matchResult = match.copyWith(name: "${basePath ??= ''}${settings.name}") as MatchResult;
      RouteData data;
      if (matchResult.isParent) {
        data = _ParentRouteData(
          matchResult: matchResult,
          initialRoute: matchResult.rest.toString(),
          router: matchResult.routeDef.router(),
        );
      } else {
        data = RouteData(matchResult);
      }
      print("pushing: $data");

      return matchResult.routeDef.builder(data);
    }
    return null;
  }

  // a shorthand for calling the onGenerateRoute function
  // when using Router directly in MaterialApp or such
  // Router().onGenerateRoute becomes Router()
  Route<dynamic> call(RouteSettings settings) => onGenerateRoute(settings);

  MatchResult findFullMatch(RouteSettings settings) {
    // deep links are  pre-matched
    MatchResult matchResult;
    if (settings is MatchResult) {
      matchResult = settings;
    } else {
      final matcher = RouteMatcher(settings);
      for (var route in routes) {
        var match = matcher.match(route, fullMatch: true);
        if (match != null) {
          matchResult = match;
          break;
        }
      }
    }
    return matchResult;
  }

  List<MatchResult> allMatches(RouteMatcher matcher) {
    var matches = <MatchResult>[];
    for (var route in routes) {
      var matchResult = matcher.match(route);
      if (matchResult != null) {
        matches.add(matchResult);
        if (matchResult.isParent || !matchResult.hasRest) {
          break;
        }
      }
    }
    return matches;
  }

  MatchResult match(RouteSettings settings) {
    final matcher = RouteMatcher(settings);
    for (var route in routes) {
      var match = matcher.match(route);
      if (match != null) {
        return match;
      }
    }
    return null;
  }
}

class RouteDef {
  final String template;
  final List<Type> guards;
  final RouterBuilder router;
  final AutoRouteFactory builder;
  final Pattern pattern;

  RouteDef(this.template, {this.guards, this.router, this.builder}) : pattern = _buildPathPattern(template);

  static Pattern _buildPathPattern(String template) {
    return '^${template.replaceAllMapped(RegExp(r':([^/]+)|([*])'), (m) {
      if (m[1] != null) {
        return '(?<${m[1]}>[^/]+)';
      } else {
        return ".*";
      }
    })}';
  }

//  bool get hasGuards => guards?.isNotEmpty == true;
//
//  bool get isParent => router != null;
}
