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

class UrlTree {
  final List<PageRouteInfo> routes;
  const UrlTree(this.routes);

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
