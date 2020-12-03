import 'package:auto_route/src/route/page_route_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show RouteInformation, RouteInformationParser;
import 'package:path/path.dart' as p;

import '../../matcher/route_matcher.dart';
import '../../utils.dart';

class NativeRouteInfoParser extends RouteInformationParser<List<PageRouteInfo>> {
  final RoutesCollection _collection;

  NativeRouteInfoParser(this._collection) : assert(_collection != null);

  @override
  Future<List<PageRouteInfo>> parseRouteInformation(RouteInformation routeInformation) async {
    var matches = RouteMatcher(_collection).match(routeInformation.location);
    var routes;
    if (matches != null) {
      routes = matches.map((m) => PageRouteInfo.fromMatch(m)).toList(growable: false);
    }
    return SynchronousFuture<List<PageRouteInfo>>(routes);
  }

  @override
  RouteInformation restoreRouteInformation(List<PageRouteInfo> routes) {
    String location = _getNormalizedPath(routes);
    print(location);
    return RouteInformation(location: location);
  }
}

class WebRouteInfoParser extends RouteInformationParser<List<PageRouteInfo>> {
  final RoutesCollection _collection;

  WebRouteInfoParser(this._collection) : assert(_collection != null);

  @override
  Future<List<PageRouteInfo>> parseRouteInformation(RouteInformation routeInformation) async {
    var matches = RouteMatcher(_collection).match(routeInformation.location, returnOnFirstMatch: true);
    var routes;
    if (matches != null) {
      routes = matches.map((m) => PageRouteInfo.fromMatch(m)).toList();
    }
    return SynchronousFuture<List<PageRouteInfo>>(routes);
  }

  @override
  RouteInformation restoreRouteInformation(List<PageRouteInfo> routes) {
    String location = _getNormalizedPath(routes);

    return RouteInformation(location: location);
  }
}

String _getNormalizedPath(List<PageRouteInfo> routes) {
  var fullPath = p.joinAll(routes.map((e) => e.path));
  var normalized = p.normalize(fullPath);
  var query = routes.last.queryParams;
  if (!mapNullOrEmpty(query)) {
    normalized += "?${query.keys.map((k) => '$k=${query[k]}').join('&')}";
  }
  var frag = routes.last.fragment;
  if (frag != null && frag.isNotEmpty) {
    normalized += "#$frag";
  }
  return normalized;
}
