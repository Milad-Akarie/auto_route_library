import 'package:auto_route/src/matcher/route_matcher.dart';
import 'package:auto_route/src/route/page_route_info.dart';
import 'package:auto_route/src/router/extended_page.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
class RouteData {
  final RouteData parent;
  final PageRouteInfo route;
  final String path;
  final String key;
  final String fragment;
  final Map<String, dynamic> queryParams;
  final Map<String, dynamic> pathParams;
  final Object args;
  final List<RouteMatch> initialSegments;
  final String group;

  const RouteData({
    @required this.path,
    @required this.key,
    @required this.queryParams,
    @required this.pathParams,
    @required this.route,
    this.group,
    this.initialSegments,
    this.fragment,
    this.args,
    this.parent,
  }) : assert(queryParams != null);

  // String get fullPath => RouteUrl.fromRouteData(this).normalizedPath;

  List<RouteData> get breadcrumbs => List.unmodifiable([
        if (parent != null) ...parent.breadcrumbs,
        this,
      ]);

  static RouteData of(BuildContext context) {
    var settings = ModalRoute.of(context)?.settings;
    if (settings != null && settings is ExtendedPage) {
      return settings.data;
    } else {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteData &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          key == other.key &&
          MapEquality().equals(queryParams, other.queryParams);

  @override
  int get hashCode => key.hashCode ^ queryParams.hashCode;

  @override
  String toString() {
    return 'RouteData{pathName: $path, path: $key, queryParams: $queryParams}';
  }
}
