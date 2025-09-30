import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

/// Helper to through flutter errors if [condition] is true
void throwIf(bool condition, String message, {Element2? element}) {
  if (condition) {
    throwError(message, element: element);
  }
}

/// Helper to through flutter errors
void throwError(String message, {Element2? element}) {
  throw InvalidGenerationSourceError(
    message,
    element: element,
  );
}

/// Extension helpers for [DartType]
extension DartTypeX on DartType {
  /// Returns the display string of this type
  /// without nullability suffix
  String get nameWithoutSuffix {
    final name = getDisplayString();
    return name.endsWith('?') ? name.substring(0, name.length - 1) : name;
  }
}
