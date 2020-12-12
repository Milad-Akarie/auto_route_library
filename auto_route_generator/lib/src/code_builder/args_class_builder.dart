import 'package:auto_route_generator/route_config_resolver.dart';
import 'package:code_builder/code_builder.dart';

import 'library_builder.dart';

Class buildArgsClass(RouteConfig r) => Class(
      (b) => b
        ..name = "${r.className}Args"
        ..extend = refer("RouteArgs", autoRouteImport)
        ..fields.addAll(r.argParams.map(
          (param) => Field((b) => b
            ..modifier = FieldModifier.final$
            ..name = param.name
            ..type = param is FunctionParamConfig ? param.funRefer : param.type.refer),
        ))
        ..constructors.add(
          Constructor(
            (b) => b
              ..optionalParameters.addAll(
                r.argParams.map(
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
                  literalList(r.argParams.map((e) => refer(e.name))),
                ]).code,
              ),
          ),
        ),
    );
