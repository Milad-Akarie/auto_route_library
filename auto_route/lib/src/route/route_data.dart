import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/route/page_route_info.dart';
import 'package:flutter/widgets.dart';

@immutable
class RouteData {
  final RouteData parent;
  final PageRouteInfo route;
  final String key;
  final String path;
  final String fragment;
  final Parameters queryParams;
  final Parameters pathParams;
  final Object _args;

  const RouteData({
    @required this.path,
    @required this.key,
    @required this.queryParams,
    @required this.pathParams,
    @required this.route,
    this.fragment,
    Object args,
    this.parent,
  }) : _args = args;

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

  T getArgs<T>({T Function() orElse}) {
    if (_args == null) {
      if (orElse == null) {
        throw FlutterError('${T.toString()} can not be null because it has required parameters');
      }
      return orElse();
    }
    if (_args is! T) {
      throw FlutterError('Expected [${T.toString()}],  found [${_args?.runtimeType}]');
    }
    return _args as T;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteData &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          key == other.key &&
          queryParams == other.queryParams;

  @override
  int get hashCode => key.hashCode ^ queryParams.hashCode;

  @override
  String toString() {
    return 'RouteData{pathName: $path, path: $key, queryParams: $queryParams}';
  }
}
