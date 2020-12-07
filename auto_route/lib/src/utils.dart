bool mapNullOrEmpty(Map map) {
  return (map == null || map.isEmpty);
}

bool listNullOrEmpty(Iterable iterable) {
  return (iterable == null || iterable.isEmpty);
}

abstract class RegexUtils {
  static Pattern compilePattern(String template, bool fullMatch) {
    assert(template != null);
    var pattern = template.replaceAllMapped(RegExp(r':([^/|?]+)|([*])'), (m) {
      if (m[1] != null) {
        return '/?(?<${m[1]}>[^/]+)';
      } else {
        return ".*";
      }
    });
    var regBound = RegExp(r'[a-zA-z]+$').hasMatch(template) ? r'\b/?' : '';
    return '^$pattern${fullMatch ? r'$' : regBound}';
  }
}
