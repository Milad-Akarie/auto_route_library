import 'package:auto_route/src/matcher/route_match.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

import '../../auto_route.dart';
import '../utils.dart';

@optionalTypeArgs
class PageRouteInfo<T> {
  final String _name;
  final String path;
  final T? args;
  final RouteMatch? match;
  final Map<String, dynamic> params;
  final Map<String, dynamic> queryParams;
  final List<PageRouteInfo>? initialChildren;

  const PageRouteInfo(
    this._name, {
    required this.path,
    this.initialChildren,
    this.match,
    this.args,
    this.params = const {},
    this.queryParams = const {},
  });

  String get routeName => _name;

  String get stringMatch {
    if (match != null) {
      return p.joinAll(match!.segments);
    }
    return _expand(path, params);
  }

  String get fullPath => p.joinAll([stringMatch, if (hasInitialChildren) initialChildren!.last.fullPath]);

  bool get hasInitialChildren => initialChildren?.isNotEmpty == true;

  bool get fromRedirect => match?.fromRedirect == true;

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

  PageRouteInfo.fromMatch(RouteMatch match)
      : args = null,
        this.match = match,
        _name = match.config.name,
        path = match.config.path,
        params = match.pathParams.rawMap,
        queryParams = match.queryParams.rawMap,
        initialChildren = match.children?.map((m) => PageRouteInfo.fromMatch(m)).toList();

// maybe?
  Future<void> show(BuildContext context) {
    return context.router.push(this);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageRouteInfo &&
          runtimeType == other.runtimeType &&
          _name == other._name &&
          path == other.path &&
          MapEquality().equals(params, other.params) &&
          MapEquality().equals(queryParams, other.queryParams);

  @override
  int get hashCode => _name.hashCode ^ path.hashCode ^ params.hashCode ^ queryParams.hashCode;
}
