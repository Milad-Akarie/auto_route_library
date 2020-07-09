import 'package:auto_route/auto_route.dart';

class RouteDef {
  final String template;
  final List<Type> guards;
  final RouterBuilder innerRouter;
  final Pattern pattern;
  final Type page;

  RouteDef(
    this.template, {
    this.page,
    this.guards,
    this.innerRouter,
  }) : pattern = _buildPathPattern(template);

  static Pattern _buildPathPattern(String template) {
    var regEx = template.replaceAllMapped(RegExp(r':([^/]+)|([*])'), (m) {
      if (m[1] != null) {
        return '(?<${m[1]}>[^/]+)';
      } else {
        return ".*";
      }
    });
    // include trailing slash
    return '$regEx';
  }
}
