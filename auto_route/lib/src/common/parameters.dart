import 'package:collection/collection.dart';

class Parameters {
  final Map<String, String> _params;

  Parameters(Map<String, String> params) : _params = params ?? {};

  Map<String, String> get rawMap => _params;

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

  int getInt(String key, [int defaultValue]) =>
      _params[key] == null ? null : int.tryParse(_params[key]) ?? defaultValue;

  double getDouble(String key, [double defaultValue]) =>
      _params[key] == null ? null : double.tryParse(_params[key]) ?? defaultValue;

  num getNum(String key, [num defaultValue]) =>
      _params[key] == null ? null : num.tryParse(_params[key]) ?? defaultValue;

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
