/// A utility to re-case a string to kabab-case
String toKebabCase(String s) {
  // Both groups of the pattern take part in every match, so neither is null.
  return s.replaceAllMapped(
    RegExp('(.+?)([A-Z])'),
    (match) => '${match.group(1)!}-${match.group(2)!}'.toLowerCase(),
  );
}
