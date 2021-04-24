import 'package:auto_route/src/route/page_route_info.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show RouteInformation, RouteInformationParser;
import 'package:path/path.dart' as p;

import '../../matcher/route_matcher.dart';

class DefaultRouteParser extends RouteInformationParser<UrlState> {
  final RouteMatcher _matcher;
  final bool includePrefixMatches;

  DefaultRouteParser(this._matcher, {this.includePrefixMatches = false});

  @override
  Future<UrlState> parseRouteInformation(RouteInformation routeInformation) async {
    var routes = <PageRouteInfo>[];
    final uri = Uri.parse(routeInformation.location ?? '');
    var matches = _matcher.matchUri(uri, includePrefixMatches: includePrefixMatches);
    if (matches != null) {
      routes.addAll(matches.map((m) => PageRouteInfo.fromMatch(m)));
    }
    return SynchronousFuture<UrlState>(UrlState(uri, routes));
  }

  @override
  RouteInformation restoreRouteInformation(UrlState tree) {
    return RouteInformation(location: tree.url.isEmpty ? '/' : tree.url);
  }
}

@immutable
class UrlState {
  final List<PageRouteInfo> segments;
  final Uri uri;

  const UrlState(this.uri, this.segments);

  String get url => uri.toString();

  String get path => uri.path;

  factory UrlState.fromRoutes(List<PageRouteInfo> routes) {
    return UrlState(_buildUri(routes), routes);
  }

  bool get hasSegments => segments.isNotEmpty;

  PageRouteInfo? get topRoute => hasSegments ? segments.last : null;

  List<PageRouteInfo> childrenOfSegment(String path) {
    return _findSegment(segments, (route) => route.stringMatch == path)?.children ?? const [];
  }

  PageRouteInfo? _findSegment(
    List<PageRouteInfo> segments,
    bool Function(PageRouteInfo segment) predicate,
  ) {
    for (var segment in segments) {
      if (predicate(segment)) {
        return segment;
      } else if (segment.hasChildren) {
        var subSegment = _findSegment(segment.children!, predicate);
        if (subSegment != null) {
          return subSegment;
        }
      }
    }
  }

  List<PageRouteInfo> childrenOfSegmentNamed(String routeName) {
    return _findSegment(segments, (route) => route.routeName == routeName)?.children ?? const [];
  }

  static Uri _buildUri(List<PageRouteInfo> routes) {
    var fullPath = '';
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
    if (lastSegment.fragment.isNotEmpty == true) {
      fragment = lastSegment.fragment;
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
      other is UrlState && runtimeType == other.runtimeType && ListEquality().equals(segments, other.segments);

  @override
  int get hashCode => ListEquality().hash(segments);
}
