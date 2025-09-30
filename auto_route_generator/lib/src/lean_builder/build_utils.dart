import 'package:lean_builder/builder.dart';
import 'package:lean_builder/element.dart';

/// Helper to through flutter errors if [condition] is true
void throwIf(bool condition, String message, {Element? element}) {
  if (condition) {
    throwError(message, element: element);
  }
}

/// Helper to through flutter errors
void throwError(String message, {Element? element}) {
  throw InvalidGenerationSourceError(
    message,
    element: element,
  );
}
