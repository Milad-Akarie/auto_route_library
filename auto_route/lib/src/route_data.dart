import 'package:flutter/material.dart';
import 'package:uri/uri.dart';

class RouteData<T> {
  final RouteSettings _routeSettings;
  final Uri _uri;
  final String template;
  final bool nullOk;
  T _args;

  RouteData(
    this._routeSettings,
    this.template, {
    this.nullOk = true,
  }) : _uri = Uri.tryParse(_routeSettings.name) {
    var parser = UriParser(UriTemplate(template));
    _pathParams = Parameters(parser.parse(_uri));
    if (hasInvalidArgs()) {
      throw FlutterError('Expected ${T.toString()} got ${_routeSettings.arguments.runtimeType}');
    }
    _args = _routeSettings.arguments;
  }

  String get name => _uri?.path ?? _routeSettings.name;

  Parameters get queryParams => Parameters(_uri?.queryParameters);

  Parameters _pathParams;

  Parameters get pathParams => _pathParams;

  T get args => _args;

  bool hasInvalidArgs() {
    if (!nullOk) {
      return (_routeSettings.arguments is! T);
    } else {
      return (_routeSettings.arguments != null && _routeSettings.arguments is! T);
    }
  }
}

class Parameters {
  final Map<String, String> _pathParams;

  Parameters(Map<String, String> params) : _pathParams = params ?? {};

  Map<String, String> get input => _pathParams;

  _ParameterValue operator [](String key) => _ParameterValue(_pathParams[key]);
}

class _ParameterValue {
  final dynamic _value;

  const _ParameterValue(this._value);

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
  final Uri _uri;

  RouteMatcher(this._uri);

  bool hasFullMatch(String template) {
    if (template == _uri.path) {
      return true;
    }
    final match = UriParser(UriTemplate(template)).match(_uri);
    return match != null && match.rest.pathSegments.isEmpty;
  }

  bool iterateMatches(
    Set<String> templates, {
    @required Function(String match, String template) onMatch,
  }) {
    bool every = false;
    for (var template in templates) {
      var match = UriParser(UriTemplate(template)).match(_uri);
      if (match != null) {
        var segmentToPush = _uri.path;
        if (match.rest.pathSegments.isNotEmpty) {
          segmentToPush = _uri.path.replaceFirst('${match.rest}', '');
        } else {
          every = true;
        }
        onMatch(segmentToPush, template);
      } else {
        break;
      }
    }
    return every;
  }
}
