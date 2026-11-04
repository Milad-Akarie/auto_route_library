import 'package:auto_route/src/route/errors.dart';
import 'package:collection/collection.dart';

/// This class helps read typed data from
/// raw maps, it's used for both path-parameters and query-parameters
class Parameters {
  /// default construct
  const Parameters(Map<String, dynamic>? params) : _params = params ?? const {};
  final Map<String, dynamic> _params;

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
  Parameters operator +(Parameters other) => .new({..._params, ...other._params});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Parameters &&
          runtimeType == other.runtimeType &&
          const MapEquality<dynamic, dynamic>(values: DeepCollectionEquality()).equals(_params, other._params);

  @override
  int get hashCode => const MapEquality<dynamic, dynamic>().hash(_params);

  /// Helper getter to `_params.isNotEmpty`
  bool get isNotEmpty => _params.isNotEmpty;

  /// Helper getter to `_params.isEmpty`
  bool get isEmpty => _params.isEmpty;

  /// returns the value corresponding with [key] as is, without type checking
  /// if null returns [defaultValue]
  dynamic get(String key, [dynamic defaultValue]) {
    return _params[key] ?? defaultValue;
  }

  /// returns the value corresponding with [key] corresponding with [key] as nullable [String]
  /// if null returns [defaultValue]
  ///
  /// A key repeated in the url (`?tag=red&tag=blue`) gives its last value, as
  /// [Uri.queryParameters] does; any other value gives its `toString()`.
  String? optString(String key, [String? defaultValue]) => _stringOf(_params[key]) ?? defaultValue;

  /// returns the value corresponding with [key] as [String]
  /// if null returns [defaultValue]
  ///
  /// Reads a repeated key or a non-String value as [optString] does.
  String getString(String key, [String? defaultValue]) {
    final val = _stringOf(_params[key]) ?? defaultValue;
    if (val == null) {
      throw MissingRequiredParameterError('Failed to parse [String] $key value from ${_params[key]}');
    }
    return val;
  }

  // The router keeps a repeated query key as a list of its values.
  static String? _stringOf(Object? value) => switch (value) {
    null => null,
    final String value => value,
    final List<Object?> values => values.isEmpty ? null : values.last?.toString(),
    _ => value.toString(),
  };

  /// returns the value corresponding with [key] as nullable `Int`
  /// if null returns [defaultValue]
  int? optInt(String key, [int? defaultValue]) {
    final param = _params[key];
    if (param == null) {
      return defaultValue;
    } else if (param is int) {
      return param;
    }
    return int.tryParse(param.toString()) ?? defaultValue;
  }

  /// returns the value corresponding with [key] as `Int`
  /// if null returns [defaultValue]
  int getInt(String key, [int? defaultValue]) {
    final val = optInt(key, defaultValue);
    if (val == null) {
      throw MissingRequiredParameterError('Failed to parse [int] $key value from ${_params[key]}');
    }
    return val;
  }

  /// returns the value corresponding with [key] as nullable [double]
  /// if null returns [defaultValue]
  double? optDouble(String key, [double? defaultValue]) {
    final param = _params[key];
    if (param == null) {
      return defaultValue;
    } else if (param is double) {
      return param;
    }
    return double.tryParse(param.toString()) ?? defaultValue;
  }

  /// returns the value corresponding with [key] as [double]
  /// if null returns [defaultValue]
  double getDouble(String key, [double? defaultValue]) {
    final val = optDouble(key, defaultValue);
    if (val == null) {
      throw MissingRequiredParameterError('Failed to parse [double] $key value from ${_params[key]}');
    }
    return val;
  }

  /// returns the value corresponding with [key] as  nullable [num]
  /// if null returns [defaultValue]
  num? optNum(String key, [num? defaultValue]) {
    final param = _params[key];
    if (param == null) {
      return defaultValue;
    } else if (param is num) {
      return param;
    }
    return num.tryParse(param.toString()) ?? defaultValue;
  }

  /// returns the value corresponding with [key] as  [num]
  /// if null returns [defaultValue]
  num getNum(String key, [num? defaultValue]) {
    final val = optNum(key, defaultValue);
    if (val == null) {
      throw MissingRequiredParameterError('Failed to parse [num] $key value from ${_params[key]}');
    }
    return val;
  }

  /// returns the value corresponding with [key] as nullable [bool]
  /// if null returns [defaultValue]
  ///
  /// A [bool] value is returned as it is, which is what a route pushed with
  /// `queryParams: {'f': true}` or restored from saved state holds. Any other
  /// value is read from its text: 'true' or 'false', in any case.
  bool? optBool(String key, [bool? defaultValue]) {
    final param = _params[key];
    if (param is bool) return param;
    switch (param?.toString().toLowerCase()) {
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
    final val = optBool(key, defaultValue);
    if (val == null) {
      throw MissingRequiredParameterError('Failed to parse [bool] $key value from ${_params[key]}');
    }
    return val;
  }

  /// returns the value corresponding with [key] as nullable [List<String>]
  List<String> getList(String key, [List<String>? defaultValue]) {
    final val = _params[key] ?? defaultValue;
    if (val == null) {
      throw MissingRequiredParameterError('Failed to parse [List<String>] $key value from ${_params[key]}');
    }
    if (val is List) {
      return val.map((e) => e.toString()).toList();
    }
    return [val.toString()];
  }

  /// returns the value corresponding with [key] as nullable [List<String>]
  /// if null returns [defaultValue]
  List<String>? optList(String key, [List<String>? defaultValue]) {
    final val = _params[key];
    if (val == null) {
      return defaultValue;
    }
    if (val is List) {
      return val.map((e) => e.toString()).toList();
    }
    return [val.toString()];
  }
}
