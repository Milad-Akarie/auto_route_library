import 'package:auto_route/src/route/errors.dart';
import 'package:collection/collection.dart';

/// This class helps read typed data from
/// raw maps, it's used for both path-parameters and query-parameters
class Parameters {
  final Map<String, dynamic> _params;

  /// default construct
  const Parameters(Map<String, dynamic>? params) : _params = params ?? const {};

  /// returns the raw map passed to the constructor
  Map<String, dynamic> get rawMap => _params;

  // coverage:ignore-start
  @override
  String toString() {
    return _params.toString();
  }
  // coverage:ignore-end

  /// merges the value of two instances of [Parameters] classes
  /// and returns a new instance containing the merged values.
  Parameters operator +(Parameters other) => Parameters({..._params, ...other._params});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Parameters &&
          runtimeType == other.runtimeType &&
          const MapEquality(
            values: DeepCollectionEquality(),
          ).equals(_params, other._params);

  @override
  int get hashCode => const MapEquality().hash(_params);

  /// Helper getter to [_params.isNotEmpty]
  bool get isNotEmpty => _params.isNotEmpty;

  /// Helper getter to [_params.isEmpty]
  bool get isEmpty => _params.isEmpty;

  /// returns the value corresponding with [key] as is, without type checking
  /// if null returns [defaultValue]
  dynamic get(String key, [defaultValue]) {
    return _params[key] ?? defaultValue;
  }

  /// returns the value corresponding with [key] corresponding with [key] as nullable [String]
  /// if null returns [defaultValue]
  String? optString(String key, [String? defaultValue]) => _params[key] ?? defaultValue;

  /// returns the value corresponding with [key] as [String]
  /// if null returns [defaultValue]
  String getString(String key, [String? defaultValue]) {
    var val = _params[key] ?? defaultValue;
    if (val == null) {
      throw MissingRequiredParameterError('Failed to parse [String] $key value from ${_params[key]}');
    }
    return val;
  }

  /// returns the value corresponding with [key] as nullable [Int]
  /// if null returns [defaultValue]
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

  /// returns the value corresponding with [key] as [Int]
  /// if null returns [defaultValue]
  int getInt(String key, [int? defaultValue]) {
    var val = optInt(key, defaultValue);
    if (val == null) {
      throw MissingRequiredParameterError('Failed to parse [int] $key value from ${_params[key]}');
    }
    return val;
  }

  /// returns the value corresponding with [key] as nullable [double]
  /// if null returns [defaultValue]
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

  /// returns the value corresponding with [key] as [double]
  /// if null returns [defaultValue]
  double getDouble(String key, [double? defaultValue]) {
    var val = optDouble(key, defaultValue);
    if (val == null) {
      throw MissingRequiredParameterError('Failed to parse [double] $key value from ${_params[key]}');
    }
    return val;
  }

  /// returns the value corresponding with [key] as  nullable [num]
  /// if null returns [defaultValue]
  num? optNum(String key, [num? defaultValue]) {
    var param = _params[key];
    if (param == null) {
      return defaultValue;
    } else if (param is num) {
      return param;
    } else {
      return num.tryParse(param.toString()) ?? defaultValue;
    }
  }

  /// returns the value corresponding with [key] as  [num]
  /// if null returns [defaultValue]
  num getNum(String key, [num? defaultValue]) {
    var val = optNum(key, defaultValue);
    if (val == null) {
      throw MissingRequiredParameterError('Failed to parse [num] $key value from ${_params[key]}');
    }
    return val;
  }

  /// returns the value corresponding with [key] as nullable [bool]
  /// if null returns [defaultValue]
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

  /// returns the value corresponding with [key] as [bool]
  /// if null returns [defaultValue]
  bool getBool(String key, [bool? defaultValue]) {
    var val = optBool(key, defaultValue);
    if (val == null) {
      throw MissingRequiredParameterError('Failed to parse [bool] $key value from ${_params[key]}');
    }
    return val;
  }

  /// returns the value corresponding with [key] as nullable [List<String>]
  List<String> getList(String key, [List<String>? defaultValue]) {
    var val = _params[key] ?? defaultValue;
    if (val == null) {
      throw MissingRequiredParameterError('Failed to parse [List<String>] $key value from ${_params[key]}');
    }
    if (val is List) {
      return val.map((e) => e.toString()).toList();
    } else {
      return [val.toString()];
    }
  }

  /// returns the value corresponding with [key] as nullable [List<String>]
  /// if null returns [defaultValue]
  List<String>? optList(String key, [List<String>? defaultValue]) {
    var val = _params[key];
    if (val == null) {
      return defaultValue;
    }
    if (val is List) {
      return val.map((e) => e.toString()).toList();
    } else {
      return [val.toString()];
    }
  }
}
