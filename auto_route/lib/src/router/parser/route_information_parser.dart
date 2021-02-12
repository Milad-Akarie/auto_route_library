import 'package:auto_route/src/route/page_route_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart'
    show RouteInformation, RouteInformationParser;
import 'package:path/path.dart' as p;

import '../../matcher/route_matcher.dart';
import '../../utils.dart';

class DefaultRouteParser extends RouteInformationParser<List<PageRouteInfo>> {
  final RouteMatcher _matcher;
  final bool includePrefixMatches;

  DefaultRouteParser(this._matcher, {this.includePrefixMatches = false})
      : assert(_matcher != null),
        assert(includePrefixMatches != null);

  @override
  Future<List<PageRouteInfo>> parseRouteInformation(
      RouteInformation routeInformation) async {
    var matches = _matcher.match(routeInformation.location,
        includePrefixMatches: includePrefixMatches);
    var routes;
    if (matches != null) {
      routes = matches.map((m) => m.toRoute).toList(growable: false);
    }
    return SynchronousFuture<List<PageRouteInfo>>(routes);
  }

  @override
  RouteInformation restoreRouteInformation(List<PageRouteInfo> routes) {
    final location = _getNormalizedPath(routes);
    return RouteInformation(location: location);
  }
}

String _getNormalizedPath(List<PageRouteInfo> routes) {
  var fullPath = p.joinAll([
    ...routes.where((e) => e.stringMatch.isNotEmpty).map((e) => e.stringMatch),
  ]);
  var normalized = p.normalize(fullPath);
  var query = routes.last.queryParams;
  if (!mapNullOrEmpty(query)) {
    normalized += "?${query.keys.map((k) {
      var value = query[k];
      if (value is List) {
        value = (value as List).map((v) => '$k=$v').join('&');
      }
      return '$k=$value';
    }).join('&')}";
  }
  var frag = routes.last?.match?.fragment;
  if (frag != null && frag.isNotEmpty) {
    normalized += "#$frag";
  }
  return normalized;
}
