import 'package:flutter/cupertino.dart';

/// A utility to check whether the given map
/// is null or empty
bool mapNullOrEmpty(Map? map) {
  return (map == null || map.isEmpty);
}

/// A utility to re-case a string to kabab-case
String toKebabCase(String s) {
  return s.replaceAllMapped(RegExp('(.+?)([A-Z])'), (match) => '${match.group(1)}-${match.group(2)}'.toLowerCase());
}

/// A helper assertion method that throws
/// the giving [message] if [condition] is true
void throwIf(
  bool condition,
  String message,
) {
  if (condition) {
    throw FlutterError(message);
  }
}
