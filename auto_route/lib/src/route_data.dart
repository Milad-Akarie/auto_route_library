import 'package:flutter/material.dart';
import 'package:uri/uri.dart';

import '../auto_route.dart';

@immutable
class RouteData extends RouteSettings {
  RouteData(this._routeMatch)
      : _pathParams = _parsePathParameters(_routeMatch),
        _queryParams = Parameters(_routeMatch.uri.queryParameters),
        super(name: _routeMatch.uri.path, arguments: _routeMatch.settings.arguments);

  static Parameters _parsePathParameters(MatchResult result) {
    var parser = UriParser(UriTemplate(result.template));
    return Parameters(parser.parse(result.uri));
  }

  final MatchResult _routeMatch;
  final Parameters _pathParams;
  final Parameters _queryParams;

  String get template => _routeMatch.template;

  Parameters get queryParams => _queryParams;

  Parameters get pathParams => _pathParams;

  T getArgs<T>({bool nullOk = true}) {
    if (_hasInvalidArgs<T>(nullOk)) {
      throw FlutterError('Expected ${T.toString()} got ${arguments?.runtimeType ?? 'null'}');
    }
    return arguments as T;
  }

  bool _hasInvalidArgs<T>(bool nullOk) {
    if (!nullOk) {
      return (arguments is! T);
    } else {
      return (arguments != null && arguments is! T);
    }
  }

  @override
  String toString() {
    return 'RouteData{template: ${_routeMatch.template}, path: ${_routeMatch.uri.path}, pathParams: $_pathParams, queryParams: $_queryParams}';
  }

  @override
  RouteData copyWith({String name, Object arguments}) {
    return RouteData(null);
  }

  static RouteData of(BuildContext context) {
    var modal = ModalRoute.of(context);
    if (modal != null && modal.settings is RouteData) {
      return modal.settings as RouteData;
    } else {
      return null;
    }
  }
}

class Parameters {
  final Map<String, String> _params;

  Parameters(Map<String, String> params) : _params = params ?? {};

  Map<String, String> get rawMap => _params;

  ParameterValue operator [](String key) => ParameterValue._(_params[key]);

  @override
  String toString() {
    return _params.toString();
  }
}

class ParameterValue {
  final dynamic _value;

  const ParameterValue._(this._value);

  dynamic get value => _value;

  String get stringValue => _value;

  int get intValue => _value == null ? null : int.tryParse(_value);

  double get doubleValue => _value == null ? null : double.tryParse(_value);

  num get numValue => _value == null ? null : num.tryParse(_value);

  bool get boolValue {
    switch (_value?.toLowerCase()) {
      case 'true':
        return true;
      case 'false':
        return false;
      default:
        return null;
    }
  }
}

class RouteMatcher {
  final Uri uri;

  RouteMatcher(this.uri);

  bool hasFullMatch(String template) {
    if (template == uri.path) {
      return true;
    }
    final match = UriParser(UriTemplate(template)).match(uri);
    return match != null && match.rest.pathSegments.isEmpty;
  }

  RouteSegments matchingSegments(Set<String> templates) {
    bool every = false;
    var matches = <String, String>{};
    for (var template in templates) {
      var match = UriParser(UriTemplate(template)).match(uri);
      if (match != null) {
        var segmentToPush = uri.path;
        if (match.rest.pathSegments.isNotEmpty) {
          segmentToPush = uri.path.replaceFirst('${match.rest}', '');
        } else {
          every = true;
        }
        matches[template] = segmentToPush;
      } else {
        break;
      }
    }
    return RouteSegments(matches: matches, hasFullMatch: every);
  }
}

class RouteSegments {
  final bool hasFullMatch;
  final Map<String, String> matches;

  RouteSegments({this.hasFullMatch, this.matches});
}

@immutable
class MatchResult {
  final Uri uri;
  final String template;
  final RouteSettings settings;

  MatchResult(this.settings, {this.uri, this.template});

  MatchResult prefixPath(String parentPath) {
    return MatchResult(this.settings, uri: this.uri.replace(path: '$parentPath${uri.path}'), template: this.template);
  }
}

@immutable
class ParentRouteSettings extends RouteSettings {
  final String initialRoute;
  final String template;

  ParentRouteSettings({
    @required this.template,
    @required String path,
    this.initialRoute,
    Object args,
  }) : super(name: path, arguments: args);
}

@immutable
class ChildRouteSettings extends RouteSettings {
  final String parentPath;

  ChildRouteSettings({
    @required this.parentPath,
    @required String path,
    Object args,
  }) : super(name: path, arguments: args);
}

@immutable
class ParentRouteData extends RouteData {
  final String initialRoute;
  final RouterBase router;

  ParentRouteData({
    this.initialRoute,
    this.router,
    MatchResult matchResult,
  }) : super(matchResult);

  static ParentRouteData of(BuildContext context) {
    var modal = ModalRoute.of(context);
    if (modal != null && modal?.settings is ParentRouteData) {
      return modal.settings as ParentRouteData;
    } else {
      return null;
    }
  }
}
