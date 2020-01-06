// general utils

String getImport(Uri uri) {
  if (uri == null) return null;
  final path = uri.toString();
  // we don't need to import core dart types
  // or core flutter types
  if (!path.startsWith('dart:core/') && !path.startsWith('package:flutter/')) {
    return "'$path'";
  } else
    return null;
}

String toLowerCamelCase(String s) {
  return s[0].toLowerCase() + s.substring(1);
}

String capitalize(String s) {
  return s[0].toUpperCase() + s.substring(1);
}
