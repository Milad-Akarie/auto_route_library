import 'package:auto_route_generator/route_config_resolver.dart';
import 'package:code_builder/code_builder.dart';

Class buildRouteInfo(RouteConfig r) => Class(
      (b) => b
        ..name = r.className
        ..extend = refer('PageRouteInfo', 'package:auto_route/auto_route.dart')
        ..fields.addAll([
          Field((b) => b
            ..modifier = FieldModifier.constant
            ..name = 'key'
            ..static = true
            ..type = refer('String')
            ..assignment = Code("'${r.pathName}'")),
        ])
        ..constructors.add(
          Constructor(
            (b) => b
              ..optionalParameters.addAll([
                ...buildArgParams(r.argParams),
              ])
              ..initializers.add(refer('super').call([refer('key')]).code),
          ),
        ),
    );

Iterable<Parameter> buildArgParams(List<RouteParamConfig> argParams) {
  return argParams.map(
    (p) => Parameter(
      (b) => b
        ..name = p.name
        ..named = true
        ..required = p.isRequired
        ..type = refer(p.type),
    ),
  );
}
