import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as p;

import '../../auto_route.dart';

/// This is the result returned by [RouteMatcher]
/// when a match is found
@immutable
class RouteMatch<T> {
  /// The extracted path params either from rawPath or
  /// [PageRouteInfo] implementation
  final Parameters params;

  /// The extracted path params either from rawPath or
  /// [PageRouteInfo] implementation
  final Parameters queryParams;

  /// The list of child matches of this match
  final List<RouteMatch>? children;

  /// The url fragment form [Uri.fragment]
  final String fragment;

  /// The expended path segments of this match
  final List<String> segments;

  /// If this match is a result of a [RedirectRoute]
  /// this will be populated with that route's path
  ///
  /// otherwise it will be null
  final String? redirectedFrom;

  /// The expended path of this match
  /// e.g [path] = /path/:id => [stringMatch] = 'path/1'
  final String stringMatch;

  /// The typed args extracted from [PageRouteInfo.args]
  final T? args;

  /// The page key to be used in [AutoRoutePage.canUpdate]
  final LocalKey key;

  final AutoRoute _config;

  /// Whether this matched is a result of [RouteMatcher.buildPathTo]
  ///
  /// this is true if match is a parent route
  /// that's not added by the user
  final bool autoFilled;

  /// The name of matched route-entry
  String get name => _config.name;

  /// The path of matched route-entry
  String get path => _config.path;

  /// The list of [AutoRouteGuard]'s this route
  /// will go through before being presented
  List<AutoRouteGuard> get guards => _config.guards;

  /// Whether is route is a parent route
  bool get isBranch => _config.hasSubTree;

  /// Helper to access [AutoRoute.meta]
  Map<String, dynamic> get meta => _config.meta;

  /// Helper to access [AutoRoute.type]
  RouteType? get type => _config.type;

  /// Helper to access [AutoRoute.keepHistory]
  bool get keepHistory => _config.keepHistory;

  /// Helper to access [AutoRoute.fullscreenDialog]
  bool get fullscreenDialog => _config.fullscreenDialog;

  /// Helper to access [AutoRoute.allowSnapshotting]
  bool get allowSnapshotting => _config.allowSnapshotting;

  /// Helper to access [AutoRoute.maintainState]
  bool get maintainState => _config.maintainState;

  /// Helper to access [AutoRoute.restorationId]
  RestorationIdBuilder? get restorationId => _config.restorationId;

  /// Helper to access [AutoRoute.title]
  TitleBuilder? get titleBuilder => _config.title;

  /// Helper to access [AutoRoute.buildPage]
  AutoRoutePage<R> buildPage<R>(RouteData data) => _config.buildPage<R>(data);

  /// The unique key of this match
  ///
  /// this key survives cloning
  /// it's used to link Routing controllers to their matches
  final LocalKey id;

  /// The path parameters of the route
  @Deprecated('Use the shorthand [params] instead')
  Parameters get pathParams => params;

  final List<AutoRouteGuard> _evaluatedGuards;

  /// Holds a list of already evaluated guards for this match
  /// before it enter guard process
  ///
  /// it is used to prevent re-evaluating guards
  List<AutoRouteGuard> get evaluatedGuards => _evaluatedGuards;

  /// Default constructor
  RouteMatch({
    required AutoRoute config,
    required this.segments,
    required this.stringMatch,
    required this.key,
    this.children,
    this.args,
    this.params = const Parameters({}),
    this.queryParams = const Parameters({}),
    this.fragment = '',
    this.redirectedFrom,
    this.autoFilled = false,
  })  : _config = config,
        _evaluatedGuards = const [],
        id = UniqueKey();

  const RouteMatch._internal({
    required AutoRoute config,
    required this.segments,
    required this.stringMatch,
    required this.key,
    this.children,
    this.args,
    this.params = const Parameters({}),
    this.queryParams = const Parameters({}),
    this.fragment = '',
    this.redirectedFrom,
    this.autoFilled = false,
    required this.id,
    List<AutoRouteGuard> evaluatedGuards = const [],
  })  : _config = config,
        _evaluatedGuards = evaluatedGuards;

  /// Whether this match has nested child-matches
  bool get hasChildren => children?.isNotEmpty == true;

  /// Whether this match is a result of a [RedirectRoute]
  bool get fromRedirect => redirectedFrom != null;

  /// Whether the matched-entry has an empty path
  bool get hasEmptyPath => _config.path.isEmpty;

  /// Collects top-most matched segments from all child-matches
  ///
  /// if [includeEmpty] is true empty segments will be included
  /// in the list
  List<String> allSegments({bool includeEmpty = false}) => [
        if (segments.isEmpty && includeEmpty) '',
        ...segments,
        if (hasChildren) ...children!.last.allSegments(includeEmpty: includeEmpty)
      ];

  /// Joins all segments to a valid path
  String get fullPath => p.joinAll(allSegments());

  /// Returns a flattened list of this match and it's sub-matches
  /// e.g if we have = RouteMatch1[RouteMatch2[RouteMatch3]]
  /// the result is [RouteMatch1,RouteMatch2,RouteMatch3]
  List<RouteMatch> get flattened {
    return [this, if (hasChildren) ...children!.last.flattened];
  }

  /// Returns a new instance of [RouteMatch]
  /// with the overridden values
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
    bool? autoFilled,
    List<AutoRouteGuard>? evaluatedGuards,
  }) {
    return RouteMatch._internal(
      config: config ?? _config,
      stringMatch: stringMatch ?? this.stringMatch,
      segments: segments ?? this.segments,
      children: children ?? this.children,
      params: pathParams ?? params,
      queryParams: queryParams ?? this.queryParams,
      fragment: fragment ?? this.fragment,
      args: args ?? this.args,
      key: key ?? this.key,
      redirectedFrom: redirectedFrom ?? this.redirectedFrom,
      autoFilled: autoFilled ?? this.autoFilled,
      id: id,
      evaluatedGuards: evaluatedGuards ?? _evaluatedGuards,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteMatch &&
          path == other.path &&
          name == other.name &&
          stringMatch == other.stringMatch &&
          params == other.params &&
          key == other.key &&
          type == other.type &&
          maintainState == other.maintainState &&
          fullscreenDialog == other.fullscreenDialog &&
          keepHistory == other.keepHistory &&
          args == other.args &&
          const ListEquality().equals(guards, other.guards) &&
          queryParams == other.queryParams &&
          const ListEquality().equals(children, other.children) &&
          fragment == other.fragment &&
          redirectedFrom == other.redirectedFrom &&
          autoFilled == other.autoFilled &&
          const ListEquality().equals(segments, other.segments) &&
          const MapEquality().equals(meta, other.meta);

  @override
  int get hashCode =>
      params.hashCode ^
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
      autoFilled.hashCode ^
      args.hashCode ^
      const ListEquality().hash(segments) ^
      const MapEquality().hash(meta);

  @override
  String toString() {
    return 'RouteMatch{ routeName: $name, pathParams: $params, queryParams: $queryParams, children: $children, fragment: $fragment, segments: $segments, redirectedFrom: $redirectedFrom,  path: $path, stringMatch: $stringMatch, args: $args, guards: $guards, key: $key}';
  }

  /// Returns a new instance of [PageRouteInfo] from
  /// the current [RouteMatch] instance
  PageRouteInfo toPageRouteInfo() => PageRouteInfo.fromMatch(this);
}

/// When a route is re-evaluated this class is used
/// to hold [currentPage] instance which will be used in-case there's no need
/// to create a new one
@immutable
class ReevaluatableRouteMatch<T, R> extends RouteMatch<T> {
  /// The current page instance
  final AutoRoutePage<R> currentPage;

  /// The original match that was used to create this instance
  final RouteMatch originalMatch;

  /// Creates a new instance of [ReevaluatableRouteMatch]
  ReevaluatableRouteMatch({
    required this.currentPage,
    required this.originalMatch,
  }) : super._internal(
          config: originalMatch._config,
          stringMatch: originalMatch.stringMatch,
          segments: originalMatch.segments,
          key: originalMatch.key,
          params: originalMatch.params,
          queryParams: originalMatch.queryParams,
          fragment: originalMatch.fragment,
          redirectedFrom: originalMatch.redirectedFrom,
          autoFilled: originalMatch.autoFilled,
          id: originalMatch.id,
          children: originalMatch.children,
          evaluatedGuards: originalMatch.evaluatedGuards,
          args: originalMatch.args,
        );

  @override
  ReevaluatableRouteMatch<T, R> copyWith({
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
    bool? autoFilled,
    List<AutoRouteGuard>? evaluatedGuards,
  }) {
    return ReevaluatableRouteMatch<T, R>(
      currentPage: currentPage,
      originalMatch: super.copyWith(
        stringMatch: stringMatch,
        pathParams: pathParams,
        queryParams: queryParams,
        children: children,
        fragment: fragment,
        segments: segments,
        redirectedFrom: redirectedFrom,
        args: args,
        key: key,
        config: config ?? _config,
        autoFilled: autoFilled ?? this.autoFilled,
        evaluatedGuards: evaluatedGuards ?? _evaluatedGuards,
      ),
    );
  }
}

/// An abstract representation of a [RouteMatch]
///
/// This is meant to be used in testing to verify
/// current hierarchy
///
/// e.g
///     expect(router.currentHierarchy(),[
///       HierarchySegment(name: HomeRoute.name, children:[
///          HierarchySegment(Tab1Route.name),
///         ]),
///      ]
///  );
class HierarchySegment {
  /// The name of the route
  final String name;

  /// The list of sub-child routes if any
  final List<HierarchySegment> children;

  /// The path parameters of the route
  final Parameters? pathParams, queryParams;

  /// Default constructor
  const HierarchySegment(
    this.name, {
    this.pathParams,
    this.queryParams,
    this.children = const [],
  });

  /// Returns a pretty json output of this hierarchy
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (pathParams?.isNotEmpty == true) 'pathParams': pathParams!.rawMap,
      if (queryParams?.isNotEmpty == true) 'queryParams': queryParams!.rawMap,
      if (children.isNotEmpty) 'children': children.map((e) => e.toJson()).toList(),
    };
  }

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

/// An extension to create a pretty json output of
/// the current hierarchy
extension PrettyHierarchySegmentX on List<HierarchySegment> {
  /// Returns a pretty json output from this hierarchy
  /// as a printable string
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
