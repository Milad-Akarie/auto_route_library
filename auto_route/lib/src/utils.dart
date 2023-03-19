import 'package:flutter/cupertino.dart';

bool mapNullOrEmpty(Map? map) {
  return (map == null || map.isEmpty);
}

String toKebabCase(String s) {
  return s.replaceAllMapped(RegExp('(.+?)([A-Z])'),
      (match) => '${match.group(1)}-${match.group(2)}'.toLowerCase());
}

void throwIf(
  bool condition,
  String message,
) {
  if (condition) {
    throw FlutterError(message);
  }
}
