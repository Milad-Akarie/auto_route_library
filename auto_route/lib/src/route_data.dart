import 'package:flutter/material.dart';
import 'package:uri/uri.dart';

@immutable
class RouteData<T> extends RouteSettings {
  final Uri _uri;
  final String template;
  final bool nullOk;
  final Parameters _pathParams;

  RouteData(
    RouteSettings _settings,
    this.template, {
    this.nullOk = true,
  })  : _uri = Uri.tryParse(_settings.name),
        _pathParams = _parsePathParamters(template, _settings.name),
        super(name: _settings.name, arguments: _settings.arguments) {
    if (_hasInvalidArgs()) {
      throw FlutterError(
          'Expected ${T.toString()} got ${_settings.arguments.runtimeType}');
    }
  }

  static Parameters _parsePathParamters(template, String path) {
    var uri = Uri.tryParse(path);
    if (uri == null) {
      return Parameters({});
    } else {
      var parser = UriParser(UriTemplate(template));
      return Parameters(parser.parse(uri));
    }
  }

  @override
  String get name => _uri?.path ?? super.name;

  Parameters get queryParams => Parameters(_uri?.queryParameters);

  Parameters get pathParams => _pathParams;

  T get args => arguments;

  bool _hasInvalidArgs() {
    if (!nullOk) {
      return (arguments is! T);
    } else {
      return (arguments != null && arguments is! T);
    }
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

  Map<String, String> get input => _params;

  ParameterValue operator [](String key) => ParameterValue._(_params[key]);
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
