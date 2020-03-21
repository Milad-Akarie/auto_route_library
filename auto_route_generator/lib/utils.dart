// general utils

import 'package:analyzer/dart/element/element.dart';

String getImport(Element element) {
  // return early if source is null
  final source = element.librarySource ?? element.source;
  if (source == null) {
    return null;
  }

  // we don't need to import core dart types
  // or core flutter types
  if (!source.isInSystemLibrary) {
    final path = source.uri.toString();
    if (!path.startsWith('package:flutter/')) {
      return "'$path'";
    }
  }
  return null;
}

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
