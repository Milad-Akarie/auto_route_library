import 'package:auto_route_generator/route_config_resolver.dart';
import 'package:code_builder/code_builder.dart';

import 'library_builder.dart';

Class buildArgsClass(RouteConfig r) => Class(
      (b) => b
        ..name = "${r.routeName}Args"
        ..extend = refer("RouteArgs", autoRouteImport)
        ..fields.addAll(r.parameters.map(
          (param) => Field((b) => b
            ..modifier = FieldModifier.final$
            ..name = param.name
            ..type = param is FunctionParamConfig ? param.funRefer : param.type.refer),
        ))
        ..constructors.addAll(
          [
            Constructor(
              (b) => b
                ..optionalParameters.addAll(
                  r.parameters.map(
                    (p) => Parameter((b) {
                      b
                        ..name = p.name
                        ..named = true
                        ..toThis = true
                        ..defaultTo = p.defaultCode;
                      if (p.isRequired) b.annotations.add(requiredAnnotation);
                      return b;
                    }),
                  ),
                )
                ..initializers.add(
                  refer('super').call([
                    literalList(r.parameters.map((e) => refer(e.name))),
                  ]).code,
                ),
            ),
            Constructor(
              (b) => b
                ..factory = true
                ..name = 'fromMatch'
                ..body = refer('${r.routeName}Args').newInstance(
                    [],
                    Map.fromEntries(
                      r.parameters.map(
                        (p) => MapEntry(
                          p.name,
                          getParamAssignment(p),
                        ),
                      ),
                    )).code
                ..requiredParameters.add(
                  Parameter(
                    (b) => b
                      ..name = 'match'
                      ..type = refer("RouteMatch", autoRouteImport),
                  ),
                ),
            )
          ],
        ),
    );

Expression getParamAssignment(ParamConfig p) {
  if (p.isPathParam) {
    return refer('match').property('pathParams').property(p.getterMethodName).call([
      literalString(p.paramName),
      if (p.defaultValueCode != null) refer(p.defaultValueCode),
    ]);
  } else if (p.isQueryParam) {
    return refer('match').property('queryParams').property(p.getterMethodName).call([
      literalString(p.paramName),
      if (p.defaultValueCode != null) refer(p.defaultValueCode),
    ]);
  } else {
    return refer('match').property('params').property(p.getterMethodName).call([
      literalString(p.paramName),
      if (p.defaultValueCode != null) refer(p.defaultValueCode),
    ]);
  }
}

// factory BookDetailsRouteArgs.fromMatch(_i1.RouteMatch match) {
// return BookDetailsRouteArgs(
// id: match.params.getInt('id'),
// );
// }
