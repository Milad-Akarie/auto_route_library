import 'package:auto_route/src/common/param_converter.dart';
import 'package:auto_route/src/route/errors.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// This class helps read typed data from
/// raw maps, it's used for both path-parameters and query-parameters
@immutable
class Parameters {
  /// default construct
  const new(Map<String, Object?>? params) : _rawMap = params ?? const {};
  final Map<String, Object?> _rawMap;

  /// returns the raw map passed to the constructor
  Map<String, Object?> get rawMap => _rawMap;

  // coverage:ignore-start
  @override
  String toString() {
    return _rawMap.toString();
  }
  // coverage:ignore-end

  /// merges the value of two instances of [Parameters] classes
  /// and returns a new instance containing the merged values.
  Parameters operator +(Parameters other) =>
      .new({..._rawMap, ...other._rawMap});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Parameters &&
          runtimeType == other.runtimeType &&
          const MapEquality<Object?, Object?>(values: DeepCollectionEquality())
              .equals(_rawMap, other._rawMap);

  @override
  int get hashCode => const MapEquality<Object?, Object?>().hash(_rawMap);

  /// Helper getter to `_rawMap.isNotEmpty`
  bool get isNotEmpty => _rawMap.isNotEmpty;

  /// Helper getter to `_rawMap.isEmpty`
  bool get isEmpty => _rawMap.isEmpty;

  /// returns the value corresponding with [key] as is, without type checking
  /// if null returns [defaultValue]
  dynamic get(String key, [dynamic defaultValue]) {
    return _rawMap[key] ?? defaultValue;
  }

  /// returns the value corresponding with [key] corresponding with [key] as
  /// nullable [String] if null returns [defaultValue]
  ///
  /// A key repeated in the url (`?tag=red&tag=blue`) gives its last value, as
  /// [Uri.queryParameters] does; any other value gives its `toString()`.
  String? optString(String key, [String? defaultValue]) =>
      _stringOf(_rawMap[key]) ?? defaultValue;

  /// returns the value corresponding with [key] as [String]
  /// if null returns [defaultValue]
  ///
  /// Reads a repeated key or a non-String value as [optString] does.
  String getString(String key, [String? defaultValue]) {
    final val = _stringOf(_rawMap[key]) ?? defaultValue;
    if (val == null) {
      throw MissingRequiredParameterError(
        'Failed to parse [String] $key value from ${_rawMap[key]}',
      );
    }
    return val;
  }

  // The router keeps a repeated query key as a list of its values.
  static String? _stringOf(Object? value) => switch (value) {
    null => null,
    final String text => text,
    final List<Object?> values => values.lastOrNull?.toString(),
    _ => value.toString(),
  };

  /// returns the value corresponding with [key] as nullable `Int`
  /// if null returns [defaultValue]
  int? optInt(String key, [int? defaultValue]) {
    final param = _rawMap[key];
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
      throw MissingRequiredParameterError(
        'Failed to parse [int] $key value from ${_rawMap[key]}',
      );
    }
    return val;
  }

  /// returns the value corresponding with [key] as nullable [double]
  /// if null returns [defaultValue]
  double? optDouble(String key, [double? defaultValue]) {
    final param = _rawMap[key];
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
      throw MissingRequiredParameterError(
        'Failed to parse [double] $key value from ${_rawMap[key]}',
      );
    }
    return val;
  }

  /// returns the value corresponding with [key] as  nullable [num]
  /// if null returns [defaultValue]
  num? optNum(String key, [num? defaultValue]) {
    final param = _rawMap[key];
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
      throw MissingRequiredParameterError(
        'Failed to parse [num] $key value from ${_rawMap[key]}',
      );
    }
    return val;
  }

  /// returns the value corresponding with [key] as nullable [bool]
  /// if null returns [defaultValue]
  ///
  /// A [bool] value is returned as it is, which is what a route pushed with
  /// `queryParams: {'f': true}` or restored from saved state holds. Any other
  /// value is read from its text: 'true' or 'false', in any case.
  // The bool is a default value, placed like getInt(key, 5), not a flag.
  bool? optBool(String key, [bool? defaultValue]) {
    final param = _rawMap[key];
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
  // The bool is a default value, placed like getInt(key, 5), not a flag.
  bool getBool(String key, [bool? defaultValue]) {
    final val = optBool(key, defaultValue);
    if (val == null) {
      throw MissingRequiredParameterError(
        'Failed to parse [bool] $key value from ${_rawMap[key]}',
      );
    }
    return val;
  }

  /// Returns the value of [key] read by [converter], or [defaultValue] when
  /// there is none.
  ///
  /// A value that is already a [T], as in a route pushed with
  /// `queryParams: {'id': UserId('7')}`, is returned as it is. Any other is
  /// read from its text, the last one for a key repeated in the url, by
  /// [ParamConverter.fromParam]; when that returns `null`, so the text is not
  /// a [T], this returns [defaultValue]. An error the converter throws is not
  /// caught.
  ///
  /// The generated route calls this for a nullable param, or one with a
  /// default, that has a converter on its annotation.
  T? optTyped<T>(String key, ParamConverter<T> converter, [T? defaultValue]) {
    final param = _rawMap[key];
    if (param is T && param != null) return param;
    final text = _stringOf(param);
    if (text == null) return defaultValue;
    return converter.fromParam(text) ?? defaultValue;
  }

  /// Returns the value of [key] read by [converter], or [defaultValue] when
  /// there is none, as [optTyped] does.
  ///
  /// Throws a [MissingRequiredParameterError] naming the key and its text
  /// when there is neither a value nor a default, or when the converter
  /// returns `null` for the text and there is no default.
  T getTyped<T>(String key, ParamConverter<T> converter, [T? defaultValue]) {
    final val = optTyped(key, converter, defaultValue);
    if (val == null) {
      throw MissingRequiredParameterError(
        'Failed to parse [$T] $key value from ${_rawMap[key]}',
      );
    }
    return val;
  }

  /// returns the value corresponding with [key] as nullable [List<String>]
  List<String> getList(String key, [List<String>? defaultValue]) {
    final val = _rawMap[key] ?? defaultValue;
    if (val == null) {
      throw MissingRequiredParameterError(
        'Failed to parse [List<String>] $key value from ${_rawMap[key]}',
      );
    }
    if (val is List) {
      return val.map((e) => e.toString()).toList();
    }
    return [val.toString()];
  }

  /// returns the value corresponding with [key] as nullable [List<String>]
  /// if null returns [defaultValue]
  List<String>? optList(String key, [List<String>? defaultValue]) {
    final val = _rawMap[key];
    if (val == null) {
      return defaultValue;
    }
    if (val is List) {
      return val.map((e) => e.toString()).toList();
    }
    return [val.toString()];
  }
}
