import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as p;
import '../../auto_route.dart';

@immutable
class RouteMatch<T> {
  final Parameters pathParams;
  final Parameters queryParams;
  final List<RouteMatch>? children;
  final String fragment;
  final List<String> segments;
  final String? redirectedFrom;
  final String stringMatch;
  final T? args;
  final LocalKey key;
  final AutoRoute _config;

  String get name => _config.name;

  String get path => _config.path;

  List<AutoRouteGuard> get guards => _config.guards;

  bool get isBranch => _config.hasSubTree;

  Map<String, dynamic> get meta => _config.meta;

  RouteType? get type => _config.type;

  TitleBuilder? get title => _config.title;

  bool get keepHistory => _config.keepHistory;

  bool get fullscreenDialog => _config.fullscreenDialog;

  bool get maintainState => _config.maintainState;


  RestorationIdBuilder? get restorationId => _config.restorationId;
  TitleBuilder? get titleBuilder => _config.title;


  const RouteMatch({
    required AutoRoute config,
    required this.segments,
    required this.stringMatch,
    required this.key,
    this.children,
    this.args,
    this.pathParams = const Parameters({}),
    this.queryParams = const Parameters({}),
    this.fragment = '',
    this.redirectedFrom,
  }) : _config = config;

  bool get hasChildren => children?.isNotEmpty == true;

  bool get fromRedirect => redirectedFrom != null;

  bool get hasEmptyPath => _config.path.isEmpty;

  List<String> allSegments({bool includeEmpty = false}) => [
        if (segments.isEmpty && includeEmpty) '',
        ...segments,
        if (hasChildren) ...children!.last.allSegments(includeEmpty: includeEmpty)
      ];

  String get fullPath => p.joinAll(allSegments());

  List<RouteMatch> get flattened {
    return [this, if (hasChildren) ...children!.last.flattened];
  }

  RouteMatch copyWith({
    String? stringMatch,
    Parameters? pathParams,
    Parameters? queryParams,
    List<RouteMatch>? children,
    String? fragment,
    List<String>? segments,
    String? redirectedFrom,
    Object? args,
    LocalKey? key,
    AutoRoute? config,
  }) {
    return RouteMatch(
      config: config ?? this._config,
      stringMatch: stringMatch ?? this.stringMatch,
      segments: segments ?? this.segments,
      children: children ?? this.children,
      pathParams: pathParams ?? this.pathParams,
      queryParams: queryParams ?? this.queryParams,
      fragment: fragment ?? this.fragment,
      args: args ?? this.args,
      key: key ?? this.key,
      redirectedFrom: redirectedFrom ?? this.redirectedFrom,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteMatch &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          name == other.name &&
          stringMatch == other.stringMatch &&
          pathParams == other.pathParams &&
          key == other.key &&
          type == other.type &&
          maintainState == other.maintainState &&
          fullscreenDialog == other.fullscreenDialog &&
          keepHistory == other.keepHistory &&
          const ListEquality().equals(guards, other.guards) &&
          queryParams == other.queryParams &&
          const ListEquality().equals(children, other.children) &&
          fragment == other.fragment &&
          redirectedFrom == other.redirectedFrom &&
          const ListEquality().equals(segments, other.segments) &&
          const MapEquality().equals(meta, other.meta);

  @override
  int get hashCode =>
      pathParams.hashCode ^
      queryParams.hashCode ^
      const ListEquality().hash(children) ^
      const ListEquality().hash(guards) ^
      fragment.hashCode ^
      redirectedFrom.hashCode ^
      path.hashCode ^
      stringMatch.hashCode ^
      name.hashCode ^
      key.hashCode ^
      maintainState.hashCode ^
      fullscreenDialog.hashCode ^
      keepHistory.hashCode ^
      type.hashCode ^
      const ListEquality().hash(segments) ^
      const MapEquality().hash(meta);

  @override
  String toString() {
    return 'RouteMatch{ routeName: $name, pathParams: $pathParams, queryParams: $queryParams, children: $children, fragment: $fragment, segments: $segments, redirectedFrom: $redirectedFrom,  path: $path, stringMatch: $stringMatch, args: $args, guards: $guards, key: $key}';
  }

  PageRouteInfo toPageRouteInfo() => PageRouteInfo.fromMatch(this);
}

class HierarchySegment {
  final String name;
  final List<HierarchySegment> children;
  final Parameters? pathParams, queryParams;

  const HierarchySegment(
    this.name, {
    this.pathParams,
    this.queryParams,
    this.children = const [],
  });

  @override
  String toString() {
    return '$name: {pathParams: $pathParams, queryParams: $queryParams, children: $children}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HierarchySegment &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          pathParams == other.pathParams &&
          queryParams == other.queryParams &&
          const ListEquality().equals(children, other.children);

  @override
  int get hashCode => name.hashCode ^ pathParams.hashCode ^ queryParams.hashCode ^ const ListEquality().hash(children);
}

extension PrettyHierarchySegmentX on List<HierarchySegment> {
  String get prettyMap {
    const encoder = JsonEncoder.withIndent('  ');

    Map toMap(List<HierarchySegment> segments) {
      return Map.fromEntries(segments.map(
        (e) => MapEntry(e.name, {
          if (e.pathParams?.isNotEmpty == true) 'pathParams': e.pathParams!.rawMap,
          if (e.queryParams?.isNotEmpty == true) 'queryParams': e.queryParams!.rawMap,
          if (e.children.isNotEmpty) 'children': toMap(e.children),
        }),
      ));
    }

    return encoder.convert(toMap(this));
  }
}
