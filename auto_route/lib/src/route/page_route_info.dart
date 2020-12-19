import 'package:auto_route/src/matcher/route_match.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

import '../../auto_route.dart';
import '../utils.dart';

@immutable
class PageRouteInfo extends Equatable {
  final String _name;
  final String path;
  final RouteMatch match;
  final Map<String, dynamic> params;
  final List<PageRouteInfo> initialChildren;
  final List<Object> argProps;

  const PageRouteInfo(
    this._name, {
    @required this.path,
    this.initialChildren,
    this.match,
    this.params,
    this.argProps,
  });

  String get routeName => _name;

  String get stringMatch {
    if (match != null) {
      return p.joinAll(match.segments);
    }
    return _expand(path, params);
  }

  String get fullPath =>
      p.joinAll([stringMatch, if (hasChildren) initialChildren.last.fullPath]);

  bool get hasChildren => !listNullOrEmpty(initialChildren);

  static String _expand(String template, Map<String, dynamic> params) {
    if (mapNullOrEmpty(params)) {
      return template;
    }
    var paramsRegex = RegExp(":(${params.keys.join('|')})");
    var path = template.replaceAllMapped(paramsRegex, (match) {
      return params[match.group(1)]?.toString() ?? '';
    });
    return path;
  }

  @override
  String toString() {
    return 'Route{name: $_name, path: $path, params: $params}';
  }

  PageRouteInfo.fromMatch(this.match)
      : _name = match.config.name,
        path = match.config.path,
        params = match.params.rawMap,
        argProps = const [],
        initialChildren = match.buildChildren();

// maybe?
  Future<void> show(BuildContext context) {
    return context.router.push(this);
  }

  @override
  List<Object> get props => [
        _name,
        path,
        match,
        params,
        initialChildren,
        if (argProps != null) ...argProps,
      ];
}

class RouteData<T extends PageRouteInfo> {
  final PageRouteInfo route;
  final RouteData parent;
  final RouteConfig config;

  const RouteData({
    this.route,
    this.parent,
    this.config,
  });

  List<RouteData> get breadcrumbs => List.unmodifiable([
        if (parent != null) ...parent.breadcrumbs,
        this,
      ]);

  static RouteData of(BuildContext context) {
    var scope = context.dependOnInheritedWidgetOfExactType<RouteDataScope>();
    assert(() {
      if (scope == null) {
        throw FlutterError(
            'RouteData operation requested with a context that does not include an RouteData.\n'
            'The context used to retrieve the RouteData must be that of a widget that '
            'is a descendant of a AutoRoutePage.');
      }
      return true;
    }());
    return scope.data;
  }

  T as<T extends PageRouteInfo>() {
    if (route is! T) {
      throw FlutterError(
          'Expected [${T.toString()}],  found [${route.runtimeType}]');
    }
    return route as T;
  }

  String get name => route._name;

  String get path => route.path;

  String get match => route.stringMatch;

  Parameters get pathParams => route.match?.pathParams;

  Parameters get queryParams => route.match?.queryParams;

  String get fragment => route.match?.fragment;
}
