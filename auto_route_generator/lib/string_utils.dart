import 'dart:convert';

String toLowerCamelCase(String s) {
  return s[0].toLowerCase() + s.substring(1);
}

// generate a base64 hash to be used as an identifier
String encodeString(String str) {
  if (str == null || str.isEmpty) return str;
  List<int> charUnits = List();
  for (int i = 0; i < str.length; i++) {
    charUnits.add(str.codeUnitAt(i));
  }
  return base64.encode(charUnits);
}
