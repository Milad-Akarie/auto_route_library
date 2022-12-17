bool mapNullOrEmpty(Map? map) {
  return (map == null || map.isEmpty);
}

bool listNullOrEmpty(Iterable? iterable) {
  return (iterable == null || iterable.isEmpty);
}

String toKababCase(String s) {
  return s.replaceAllMapped(RegExp('(.+?)([A-Z])'),
          (match) => '${match.group(1)}-${match.group(2)}'.toLowerCase());
}