import 'package:auto_route/src/route/page_route_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show RouteInformation, RouteInformationParser;
import 'package:path/path.dart' as p;

import '../../matcher/route_matcher.dart';
import '../../utils.dart';

class DefaultRouteParser extends RouteInformationParser<UrlTree> {
  final RouteMatcher _matcher;
  final bool includePrefixMatches;

  DefaultRouteParser(this._matcher, {this.includePrefixMatches = false});

  @override
  Future<UrlTree> parseRouteInformation(RouteInformation routeInformation) async {
    var matches = _matcher.match(routeInformation.location ?? '', includePrefixMatches: includePrefixMatches);
    var routes = <PageRouteInfo>[];
    if (matches != null) {
      routes.addAll(matches.map((m) => PageRouteInfo.fromMatch(m)));
    }
    return SynchronousFuture<UrlTree>(UrlTree(routes));
  }

  @override
  RouteInformation restoreRouteInformation(UrlTree tree) {
    return RouteInformation(location: tree.url);
  }
}

String _getNormalizedPath(List<PageRouteInfo> routes) {
  var fullPath = '/';
  //
  if (routes.isEmpty) {
    return fullPath;
  }
  //
  fullPath = p.joinAll([
    ...routes.where((e) => e.stringMatch.isNotEmpty).map((e) => e.stringMatch),
  ]);

  var normalized = p.normalize(fullPath);
  var query = routes.last.queryParams;
  if (!mapNullOrEmpty(query)) {
    normalized += "?${query.keys.map((k) {
      var value = query[k];
      if (value is List) {
        value = value.map((v) => '$k=$v').join('&');
      }
      return '$k=$value';
    }).join('&')}";
  }
  var frag = routes.last.match?.fragment;
  if (frag?.isNotEmpty == true) {
    normalized += "#$frag";
  }
  return normalized;
}

class UrlTree {
  final List<PageRouteInfo> routes;

  UrlTree(this.routes);

  String get url => uri.toString();
  String get path => uri.path;
  Uri get uri {
    var fullPath = '/';
    if (routes.isEmpty) {
      return Uri(path: fullPath);
    }
    fullPath = p.joinAll(
      routes.where((e) => e.stringMatch.isNotEmpty).map(
            (e) => e.stringMatch,
          ),
    );
    final normalized = p.normalize(fullPath);
    final lastSegment = routes.last;
    var queryParams;
    if (lastSegment.queryParams.isNotEmpty) {
      queryParams = lastSegment.queryParams;
    }

    var fragment;
    if (lastSegment.match?.fragment.isNotEmpty == true) {
      fragment = lastSegment.match!.fragment;
    }
    return Uri(
      path: normalized,
      queryParameters: queryParams,
      fragment: fragment,
    );
  }
}
