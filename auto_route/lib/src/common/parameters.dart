import 'package:collection/collection.dart';

class Parameters {
  final Map<String, dynamic> _params;

  const Parameters(Map<String, dynamic>? params) : _params = params ?? const {};

  Map<String, dynamic> get rawMap => _params;

  @override
  String toString() {
    return _params.toString();
  }

  Parameters operator +(Parameters other) =>
      Parameters({..._params, ...other._params});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Parameters &&
          runtimeType == other.runtimeType &&
          MapEquality(
            values: DeepCollectionEquality(),
          ).equals(_params, other._params);

  @override
  int get hashCode => _params.hashCode;

  dynamic get(String key, [defaultValue]) {
    return _params[key] ?? defaultValue;
  }

  String? optString(String key, [String? defaultValue]) =>
      _params[key] ?? defaultValue;

  String getString(String key, [String? defaultValue]) =>
      _params[key] ?? defaultValue;

  int? optInt(String key, [int? defaultValue]) {
    var param = _params[key];
    if (param == null) {
      return defaultValue;
    } else if (param is int) {
      return param;
    } else {
      return int.tryParse(param.toString()) ?? defaultValue;
    }
  }

  int getInt(String key, [int? defaultValue]) => optInt(key, defaultValue)!;

  double? optDouble(String key, [double? defaultValue]) {
    var param = _params[key];
    if (param == null) {
      return defaultValue;
    } else if (param is double) {
      return param;
    } else {
      return double.tryParse(param.toString()) ?? defaultValue;
    }
  }

  double getDouble(String key, [double? defaultValue]) =>
      optDouble(key, defaultValue)!;

  num? optNum(String key, [num? defaultValue]) {
    var param = _params[key];
    if (param == null) {
      return defaultValue;
    } else if (param is num) {
      return param;
    } else {
      return double.tryParse(param.toString()) ?? defaultValue;
    }
  }

  num getNum(String key, [num? defaultValue]) => optNum(key, defaultValue)!;

  bool? optBool(String key, [bool? defaultValue]) {
    switch (_params[key]?.toLowerCase()) {
      case 'true':
        return true;
      case 'false':
        return false;
      default:
        return defaultValue;
    }
  }

  bool getBool(String key, [bool? defaultValue]) => optBool(key, defaultValue)!;
}
