/// Recase a string to lowerCamelCase
String toLowerCamelCase(String s) {
  if (s.length < 2) return s.toLowerCase();
  return s[0].toLowerCase() + s.substring(1);
}

/// Capitalize a string
String capitalize(String s) {
  if (s.length < 2) return s.toUpperCase();
  return s[0].toUpperCase() + s.substring(1);
}

/// Recase a string to kabab-case
String toKababCase(String s) {
  return s.replaceAllMapped(
    RegExp('(.+?)([A-Z])'),
    (match) => '${match.group(1)!}-${match.group(2)!}'.toLowerCase(),
  );
}
