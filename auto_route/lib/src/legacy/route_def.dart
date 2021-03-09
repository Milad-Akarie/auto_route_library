import 'router_base.dart';

class RouteDef {
  final String template;
  final List<Type> guards;
  final RouterBase? generator;
  final String pattern;
  final Type page;

  RouteDef(
    this.template, {
    required this.page,
    this.guards = const [],
    this.generator,
  }) : pattern = _buildPathPattern(template);

  bool get isParent => generator != null;

  static String _buildPathPattern(String template) {
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
