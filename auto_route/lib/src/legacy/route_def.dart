import 'router_base.dart';

class RouteDef {
  final String template;
  final List<Type> guards;
  final RouterBase generator;
  final Pattern pattern;
  final Type page;

  RouteDef(
    this.template, {
    this.page,
    this.guards,
    this.generator,
  }) : pattern = _buildPathPattern(template);

  bool get isParent => generator != null;

  static Pattern _buildPathPattern(String template) {
    var regEx = template.replaceAllMapped(RegExp(r':([^/|?]+)|([*])'), (m) {
      if (m[1] != null) {
        return '?(?<${m[1]}>[^/]+)';
      } else {
        return ".*";
      }
    });
    return '^$regEx([/])?';
  }
}
