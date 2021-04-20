import 'package:auto_route/src/route/page_route_info.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show RouteInformation, RouteInformationParser;
import 'package:path/path.dart' as p;

import '../../matcher/route_matcher.dart';

class DefaultRouteParser extends RouteInformationParser<UrlTree> {
  final RouteMatcher _matcher;
  final bool includePrefixMatches;

  DefaultRouteParser(this._matcher, {this.includePrefixMatches = false});

  @override
  Future<UrlTree> parseRouteInformation(RouteInformation routeInformation) async {
    var routes = <PageRouteInfo>[];
    final uri = Uri.parse(routeInformation.location ?? '');
    var matches = _matcher.matchUri(uri, includePrefixMatches: includePrefixMatches);
    if (matches != null) {
      routes.addAll(matches.map((m) => PageRouteInfo.fromMatch(m)));
    }
    return SynchronousFuture<UrlTree>(UrlTree(uri, routes));
  }

  @override
  RouteInformation restoreRouteInformation(UrlTree tree) {
    return RouteInformation(location: tree.url);
  }
}

class UrlTree {
  final List<PageRouteInfo> routes;
  final Uri uri;

  const UrlTree(this.uri, this.routes);

  String get url => uri.toString();

  String get path => uri.path;

  factory UrlTree.fromRoutes(List<PageRouteInfo> routes) {
    return UrlTree(_buildUri(routes), routes);
  }

  bool get hasRoutes => routes.isNotEmpty;

  PageRouteInfo? get topRoute => hasRoutes ? routes.last : null;

  static Uri _buildUri(List<PageRouteInfo> routes) {
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UrlTree && runtimeType == other.runtimeType && ListEquality().equals(routes, other.routes);

  @override
  int get hashCode => ListEquality().hash(routes);
}
