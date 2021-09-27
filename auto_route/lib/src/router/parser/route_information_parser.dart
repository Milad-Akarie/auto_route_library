import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart'
    show RouteInformation, RouteInformationParser;
import 'package:path/path.dart' as p;

import '../../matcher/route_matcher.dart';

class DefaultRouteParser extends RouteInformationParser<UrlState> {
  final RouteMatcher _matcher;
  final bool includePrefixMatches;

  DefaultRouteParser(this._matcher, {this.includePrefixMatches = false});

  @override
  Future<UrlState> parseRouteInformation(
      RouteInformation routeInformation) async {
    final uri = Uri.parse(routeInformation.location ?? '');
    var matches =
        _matcher.matchUri(uri, includePrefixMatches: includePrefixMatches);
    return SynchronousFuture<UrlState>(UrlState(uri, matches ?? const []));
  }

  @override
  RouteInformation restoreRouteInformation(UrlState urlState) {
    return AutoRouteInformation(
      location: urlState.url.isEmpty ? '/' : urlState.url,
      replace: urlState.shouldReplace,
    );
  }
}

class AutoRouteInformation extends RouteInformation {
  final bool replace;

  const AutoRouteInformation({
    required String location,
    Object? state,
    this.replace = true,
  }) : super(location: location, state: state);
}

@immutable
class UrlState {
  final List<RouteMatch> segments;
  final Uri uri;
  final bool shouldReplace;

  const UrlState(this.uri, this.segments, {this.shouldReplace = false});

  String get url => uri.toString();

  String get path => uri.path;

  factory UrlState.fromSegments(List<RouteMatch> routes,
      {bool shouldReplace = false}) {
    return UrlState(
      _buildUri(routes),
      routes,
      shouldReplace: shouldReplace,
    );
  }

  bool get hasSegments => segments.isNotEmpty;

  RouteMatch? get topMatch => hasSegments ? segments.last : null;

  RouteMatch? _findSegment(
    List<RouteMatch> segments,
    bool Function(RouteMatch segment) predicate,
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

  List<RouteMatch> childrenOfSegmentNamed(String routeName) {
    return _findSegment(segments, (match) => match.name == routeName)
            ?.children ??
        const [];
  }

  static Uri _buildUri(List<RouteMatch> routes) {
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
    Map<String, dynamic> queryParams = {};
    if (lastSegment.queryParams.isNotEmpty) {
      var queries = lastSegment.queryParams.rawMap;
      for (var key in queries.keys) {
        var value = queries[key]?.toString() ?? '';
        if (value.isNotEmpty) {
          queryParams[key] = value.toString();
        }
      }
    }

    var fragment;
    if (lastSegment.fragment.isNotEmpty == true) {
      fragment = lastSegment.fragment;
    }
    return Uri(
      path: normalized,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
      fragment: fragment,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UrlState &&
          runtimeType == other.runtimeType &&
          ListEquality().equals(segments, other.segments);

  @override
  int get hashCode => ListEquality().hash(segments);

  UrlState copyWith({
    List<RouteMatch>? segments,
    Uri? uri,
    bool? replace,
  }) {
    return UrlState(
      uri ?? this.uri,
      segments ?? this.segments,
      shouldReplace: replace ?? this.shouldReplace,
    );
  }
}
