// general utils

import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

String toLowerCamelCase(String s) {
  if (s.length < 2) return s.toLowerCase();
  return s[0].toLowerCase() + s.substring(1);
}

String capitalize(String s) {
  if (s.length < 2) return s.toUpperCase();
  return s[0].toUpperCase() + s.substring(1);
}

String toKababCase(String s) {
  return s.replaceAllMapped(RegExp('(.+?)([A-Z])'),
      (match) => '${match.group(1)}-${match.group(2)}'.toLowerCase());
}

void throwIf(bool condition, String message, {Element element, String todo}) {
  if (condition) {
    throwError(message, todo: todo, element: element);
  }
}

void throwError(String message, {Element element, String todo}) {
  throw InvalidGenerationSourceError(
    message,
    todo: todo,
    element: element,
  );
}
