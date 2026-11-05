import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/matcher/route_matcher.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show RouteInformation, RouteInformationParser;
import 'package:path/path.dart' as p;

/// AutoRoute extension of [RouteInformationParser]
class DefaultRouteParser extends RouteInformationParser<UrlState> {
  /// Default constructor
  DefaultRouteParser(this._matcher, {this.includePrefixMatches = false, this.deepLinkTransformer});
  final RouteMatcher _matcher;

  /// If set to true all paths that's
  /// matched as prefix will be included in
  /// matching list.
  /// Passed to [RouteMatcher.matchUri]
  final bool includePrefixMatches;

  /// Clients can use this to intercept deep-links
  /// coming from platform and transform the [Uri].
  /// Especially useful to remove pathPrefixes use in filter-intent on Android
  /// or appLinks on Apple
  ///
  /// It's recommended to return [SynchronousFuture] of the transformed [Uri]
  /// if you're doing any async operation in the transformer
  final DeepLinkTransformer? deepLinkTransformer;

  @override
  Future<UrlState> parseRouteInformation(RouteInformation routeInformation) async {
    final resolvedUri = _normalize(await deepLinkTransformer?.call(routeInformation.uri) ?? routeInformation.uri);
    final matches = _matcher.matchUri(resolvedUri, includePrefixMatches: includePrefixMatches);
    final state = routeInformation.state;
    final savedRoutes = state is Map ? state[UrlState._savedRoutesKey] : null;
    return SynchronousFuture(
      UrlState(
        routeInformation.uri,
        matches ?? const [],
        // savedRoutes is only set when state is a Map.
        pathState: state is Map && savedRoutes != null ? state[UrlState._pathStateKey] : state,
        savedRoutes: savedRoutes,
      ),
    );
  }

  Uri _normalize(Uri uri) {
    final path = uri.path.isEmpty ? '/' : uri.path;
    return Uri(
      path: p.normalize(path),
      queryParameters: uri.queryParameters.isEmpty ? null : uri.queryParametersAll,
      fragment: uri.fragment.isEmpty ? null : uri.fragment,
    );
  }

  @override
  RouteInformation restoreRouteInformation(UrlState configuration) {
    final uri = configuration.url.isEmpty ? Uri(path: '/') : configuration.uri;
    return AutoRouteInformation._(
      uri: kIsWeb ? _WebEngineUri(uri) : uri,
      appUri: uri,
      replace: configuration.shouldReplace,
      state: configuration.savedRoutes == null
          ? configuration.pathState
          : {UrlState._savedRoutesKey: configuration.savedRoutes, UrlState._pathStateKey: configuration.pathState},
    );
  }
}

/// Escapes [uri] for the web engine, which decodes the uri the router reports
/// with Uri.decodeComponent before it writes it to the browser. That decode
/// turns an encoded '#', '&' or '/' inside a param into a real delimiter;
/// escaping every '%' once more makes it give back [uri] as it was.
@internal
Uri escapeForWebEngine(Uri uri) => Uri.parse(uri.toString().replaceAll('%', '%25'));

/// `uri` as the web engine needs it: its string is escaped for the engine, as
/// [escapeForWebEngine] does, and its parts are `uri`'s own.
///
/// The engine gets the string. Flutter's own route information provider
/// compares the parts with those of the uri the engine reported, so a report
/// of the url the browser shows replaces its entry instead of adding one.
@immutable
class _WebEngineUri implements Uri {
  _WebEngineUri(this._uri);

  final Uri _uri;

  late final String _escaped = escapeForWebEngine(_uri).toString();

  @override
  String toString() => _escaped;

  @override
  bool operator ==(Object other) => _uri == (other is _WebEngineUri ? other._uri : other);

  @override
  int get hashCode => _uri.hashCode;

  @override
  String get scheme => _uri.scheme;

  @override
  String get authority => _uri.authority;

  @override
  String get userInfo => _uri.userInfo;

  @override
  String get host => _uri.host;

  @override
  int get port => _uri.port;

  @override
  String get path => _uri.path;

  @override
  String get query => _uri.query;

  @override
  String get fragment => _uri.fragment;

  @override
  List<String> get pathSegments => _uri.pathSegments;

  @override
  Map<String, String> get queryParameters => _uri.queryParameters;

  @override
  Map<String, List<String>> get queryParametersAll => _uri.queryParametersAll;

  @override
  bool get isAbsolute => _uri.isAbsolute;

  @override
  bool get hasScheme => _uri.hasScheme;

  @override
  bool get hasAuthority => _uri.hasAuthority;

  @override
  bool get hasPort => _uri.hasPort;

  @override
  bool get hasQuery => _uri.hasQuery;

  @override
  bool get hasFragment => _uri.hasFragment;

  @override
  bool get hasEmptyPath => _uri.hasEmptyPath;

  @override
  bool get hasAbsolutePath => _uri.hasAbsolutePath;

  @override
  String get origin => _uri.origin;

  @override
  bool isScheme(String scheme) => _uri.isScheme(scheme);

  @override
  String toFilePath({bool? windows}) => _uri.toFilePath(windows: windows);

  @override
  UriData? get data => _uri.data;

  @override
  Uri replace({
    String? scheme,
    String? userInfo,
    String? host,
    int? port,
    String? path,
    Iterable<String>? pathSegments,
    String? query,
    Map<String, Object?>? queryParameters,
    String? fragment,
  }) => _uri.replace(
    scheme: scheme,
    userInfo: userInfo,
    host: host,
    port: port,
    path: path,
    pathSegments: pathSegments,
    query: query,
    queryParameters: queryParameters,
    fragment: fragment,
  );

  @override
  Uri removeFragment() => _uri.removeFragment();

  @override
  Uri resolve(String reference) => _uri.resolve(reference);

  @override
  Uri resolveUri(Uri reference) => _uri.resolveUri(reference);

  @override
  Uri normalizePath() => _uri.normalizePath();
}

/// An extended type of [RouteInformation] that holds
/// an extra property [replace] which forces the current
/// route to be replaced
@immutable
class AutoRouteInformation extends RouteInformation {
  /// Default constructor
  const AutoRouteInformation({required Uri super.uri, super.state, this.replace = true}) : appUri = null;

  const AutoRouteInformation._({required Uri super.uri, required Uri this.appUri, super.state, this.replace = true});

  /// forces the current location to be replaced with this location
  final bool replace;

  /// The app's own uri, when [uri] is escaped for the web engine
  ///
  /// [DefaultRouteParser] escapes the uri it restores on web, so every route
  /// information provider reports it whole; comparisons with the uri the
  /// platform reports use this one.
  @internal
  final Uri? appUri;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AutoRouteInformation && runtimeType == other.runtimeType && uri == other.uri && state == other.state;

  @override
  int get hashCode => replace.hashCode;
}

/// [UrlState] Holds current url state in a more structured way
/// it's used by `Router` as configuration state
@immutable
class UrlState {
  /// Default constructor
  const UrlState(this.uri, this.segments, {this.shouldReplace = false, this.pathState, @internal this.savedRoutes});

  /// Builds UrlState from list of
  /// route matches instead of uri
  factory UrlState.fromSegments(List<RouteMatch<Object?>> routes, {bool shouldReplace = false, Object? state}) {
    return UrlState(_buildUri(routes), routes, shouldReplace: shouldReplace, pathState: state);
  }

  /// Represents current router uri
  final Uri uri;

  /// The list of segments representing the current [uri]
  final List<RouteMatch<Object?>> segments;

  /// This is passed to [AutoRouteInformation.replace]
  /// when location is restored
  final bool shouldReplace;

  /// Holds instance of browser entry-state
  final Object? pathState;

  /// The pages of every router, saved for state restoration
  ///
  /// [RootStackRouter] fills it off the web, where Flutter's state
  /// restoration runs, and rebuilds its pages from it when the app is
  /// restored. [DefaultRouteParser] keeps it in [RouteInformation.state],
  /// which `Router` saves, next to [pathState]; it's not sent to the
  /// platform.
  @internal
  final Object? savedRoutes;

  static const _savedRoutesKey = 'autoRouteSavedRoutes';
  static const _pathStateKey = 'pathState';

  /// Returns the part of a [RouteInformation.state] built by
  /// [DefaultRouteParser] that's meant for the platform: [state] without
  /// the saved routes, which are only for state restoration.
  @internal
  static Object? platformState(Object? state) {
    if (state is Map && state.containsKey(_savedRoutesKey)) {
      return state[_pathStateKey];
    }
    return state;
  }

  /// Returns [uri] as a readable string, such as '/books/café?q=a b'
  ///
  /// Escapes are decoded, except those of characters that would change what
  /// the url means: '/', '?', '#' and '%' in the path, and '&', '=', '+', '#'
  /// and '%' in the query, so a param such as 'a&b' reads back whole.
  String get url => _urls[this] ??= _readable(uri.toString());

  // [url] of each state, built on first read: one navigation reads it
  // several times, and [uri] never changes.
  static final _urls = Expando<String>('url');

  static final _escapes = RegExp('(?:%[0-9A-Fa-f]{2})+');

  static String _readable(String encoded) {
    if (!encoded.contains('%')) return encoded;
    final queryStart = encoded.indexOf('?');
    final fragmentStart = encoded.indexOf('#');
    final pathEnd = queryStart >= 0 ? queryStart : (fragmentStart >= 0 ? fragmentStart : encoded.length);
    final queryEnd = fragmentStart >= 0 ? fragmentStart : encoded.length;
    return _decodeExcept(encoded.substring(0, pathEnd), '/?#%') +
        _decodeExcept(encoded.substring(pathEnd, queryEnd), '&=+#%') +
        _decodeExcept(encoded.substring(queryEnd), '%');
  }

  // Decodes the escapes in [part], keeping the ASCII characters in [keep]
  // encoded, and any bytes that aren't valid UTF-8.
  static String _decodeExcept(String part, String keep) {
    return part.replaceAllMapped(_escapes, (match) {
      final run = match[0]!;
      final bytes = [for (var i = 0; i < run.length; i += 3) int.parse(run.substring(i + 1, i + 3), radix: 16)];
      final out = StringBuffer();
      var i = 0;
      while (i < bytes.length) {
        if (bytes[i] < 0x80) {
          final char = String.fromCharCode(bytes[i]);
          out.write(keep.contains(char) ? run.substring(i * 3, i * 3 + 3) : char);
          i++;
          continue;
        }
        var end = i + 1;
        while (end < bytes.length && bytes[end] >= 0x80) {
          end++;
        }
        try {
          out.write(utf8.decode(bytes.sublist(i, end)));
        } on FormatException {
          out.write(run.substring(i * 3, end * 3));
        }
        i = end;
      }
      return out.toString();
    });
  }

  /// Returns the path of [uri]
  String get path => uri.path;

  /// Converts a list of linear route matches to
  /// to a hierarchy of routes
  /// e.g [Match1,Match2,Match3]
  /// will be [Match1[Match2[Match3]]]
  static RouteMatch<Object?> toHierarchy(List<RouteMatch<Object?>> segments) {
    if (segments.length == 1) {
      return segments.first;
    }
    return segments.first.copyWith(children: [toHierarchy(segments.sublist(1, segments.length))]);
  }

  /// Returns a new instance of [UrlState]
  /// With the flattened version of [segments]
  /// e.g if segments = [Match1[Match2[Match3]]]
  /// the result is [Match1,Match2,Match3]
  UrlState get flatten => .fromSegments(segments.last.flattened, state: pathState);

  @override
  String toString() {
    return 'UrlState{uri: $uri, shouldReplace: $shouldReplace, pathState: $pathState}';
  }

  /// Returns true if [segments] is not empty
  bool get hasSegments => segments.isNotEmpty;

  /// Returns to topMost item in the segments list
  /// Witch is the last
  RouteMatch<Object?>? get topMatch => hasSegments ? segments.last : null;

  RouteMatch<Object?>? _findSegment(
    List<RouteMatch<Object?>> segments,
    bool Function(RouteMatch<Object?> segment) predicate,
  ) {
    for (final segment in segments) {
      if (predicate(segment)) {
        return segment;
      } else if (segment.hasChildren) {
        final subSegment = _findSegment(segment.children!, predicate);
        if (subSegment != null) {
          return subSegment;
        }
      }
    }
    return null;
  }

  /// re
  List<RouteMatch<Object?>> childrenOfSegmentNamed(String routeName) {
    return _findSegment(segments, (match) => match.name == routeName)?.children ?? const [];
  }

  static Uri _buildUri(List<RouteMatch<Object?>> routes) {
    var fullPath = '/';
    if (routes.isEmpty) {
      return Uri(path: fullPath);
    }
    fullPath = p.joinAll(routes.where((e) => e.stringMatch.isNotEmpty).map((e) => e.stringMatch));
    final normalized = p.normalize(fullPath);
    final lastSegment = routes.last;
    final queryParams = <String, Object?>{};
    if (lastSegment.queryParams.isNotEmpty) {
      final queries = lastSegment.queryParams.rawMap;
      for (final key in queries.keys) {
        final value = normalizeQueryParamValue(queries[key]);
        // An empty list has no item to write, and kept it would leave a '?'.
        if (value != null && !(value is List && value.isEmpty)) {
          queryParams[key] = value;
        }
      }
    }

    String? fragment;
    if (lastSegment.fragment.isNotEmpty) {
      fragment = lastSegment.fragment;
    }
    return Uri(path: normalized, queryParameters: queryParams.isNotEmpty ? queryParams : null, fragment: fragment);
  }

  /// Stringify query param value
  static dynamic normalizeQueryParamValue(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is Iterable) {
      return value.map((el) => el?.toString()).toList();
    }
    final text = value is String ? value : value.toString();
    if (text.isEmpty) {
      return null;
    }
    return text;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UrlState &&
          runtimeType == other.runtimeType &&
          pathState == other.pathState &&
          const ListEquality<Object?>().equals(segments, other.segments);

  @override
  int get hashCode => const ListEquality<Object?>().hash(segments) ^ pathState.hashCode;

  /// Returns a new [UrlState] instance
  /// with replaced properties
  UrlState copyWith({
    List<RouteMatch<Object?>>? segments,
    Uri? uri,
    bool? shouldReplace,
    Object? pathState,
    @internal Object? savedRoutes,
  }) {
    return UrlState(
      uri ?? this.uri,
      segments ?? this.segments,
      shouldReplace: shouldReplace ?? this.shouldReplace,
      pathState: pathState ?? this.pathState,
      savedRoutes: savedRoutes ?? this.savedRoutes,
    );
  }
}
