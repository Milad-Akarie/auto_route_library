import 'package:collection/collection.dart';

class Parameters {
  final Map<String, dynamic> _params;

  Parameters(Map<String, dynamic> params) : _params = params ?? {};

  Map<String, dynamic> get rawMap => _params;

  @deprecated
  ParameterValue operator [](String key) => ParameterValue._(_params[key]);

  @override
  String toString() {
    return _params.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Parameters && runtimeType == other.runtimeType && MapEquality().equals(_params, other._params);

  @override
  int get hashCode => _params.hashCode;

  String getString(String key, [String defaultValue]) => _params[key] ?? defaultValue;

  Object get(String key) => _params[key];

  int getInt(String key, [int defaultValue]) {
    var param = _params[key];
    if (param == null) {
      return defaultValue;
    } else if (param is int) {
      return param;
    } else {
      return int.tryParse(param.toString()) ?? defaultValue;
    }
  }

  double getDouble(String key, [double defaultValue]) {
    var param = _params[key];
    if (param == null) {
      return defaultValue;
    } else if (param is double) {
      return param;
    } else {
      return double.tryParse(param.toString()) ?? defaultValue;
    }
  }

  num getNum(String key, [num defaultValue]) {
    var param = _params[key];
    if (param == null) {
      return defaultValue;
    } else if (param is num) {
      return param;
    } else {
      return double.tryParse(param.toString()) ?? defaultValue;
    }
  }

  bool getBool(String key) {
    switch (_params[key]?.toLowerCase()) {
      case 'true':
        return true;
      case 'false':
        return false;
      default:
        return null;
    }
  }
}

@deprecated
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
