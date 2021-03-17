import 'package:code_builder/code_builder.dart';

import '../models/route_config.dart';
import '../models/route_parameter_config.dart';
import '../models/router_config.dart';
import 'library_builder.dart';

List<Class> buildRouteInfoAndArgs(RouteConfig r, RouterConfig router) {
  return [
    Class(
      (b) => b
        ..name = r.routeName
        ..extend = TypeReference((b) {
          b
            ..symbol = 'PageRouteInfo'
            ..url = autoRouteImport;
          if (r.parameters.isNotEmpty) b.types.add(refer('${r.routeName}Args'));
        })
        ..fields.addAll([
          ...r.parameters.map((param) => Field((b) => b
            ..modifier = FieldModifier.final$
            ..name = param.name
            ..type = param is FunctionParamConfig ? param.funRefer : param.type.refer)),
          Field(
            (b) => b
              ..modifier = FieldModifier.constant
              ..name = 'name'
              ..static = true
              ..type = stringRefer
              ..assignment = literalString(r.routeName).code,
          )
        ])
        ..constructors.add(
          Constructor(
            (b) {
              b
                ..constant = r.parameters.isEmpty
                ..optionalParameters.addAll([
                  ...buildArgParams(r.parameters),
                  if (r.isParent)
                    Parameter((b) => b
                      ..named = true
                      ..name = 'children'
                      ..type = listRefer(pageRouteType, nullable: true)),
                ])
                ..initializers.add(refer('super').call([
                  refer('name')
                ], {
                  'path': literalString(r.pathName),
                  if (r.parameters.isNotEmpty)
                    'args': refer('${r.routeName}Args').call(
                      [],
                      Map.fromEntries(
                        r.parameters.map(
                          (p) => MapEntry(
                            p.name,
                            refer(p.name),
                          ),
                        ),
                      ),
                    ),
                  if (r.parameters.any((p) => p.isPathParam))
                    'params': literalMap(
                      Map.fromEntries(
                        r.parameters.where((p) => p.isPathParam).map(
                              (p) => MapEntry(
                                p.paramName,
                                refer(p.name),
                              ),
                            ),
                      ),
                    ),
                  if (r.parameters.any((p) => p.isQueryParam))
                    'queryParams': literalMap(
                      Map.fromEntries(
                        r.parameters.where((p) => p.isQueryParam).map(
                              (p) => MapEntry(
                                p.paramName,
                                refer(p.name),
                              ),
                            ),
                      ),
                    ),
                  if (r.isParent) 'initialChildren': refer('children'),
                }).code);
            },
          ),
        ),
    ),
    if (r.parameters.isNotEmpty)
      Class(
        (b) => b
          ..name = '${r.routeName}Args'
          ..fields.addAll([
            ...r.parameters.map((param) => Field((b) => b
              ..modifier = FieldModifier.final$
              ..name = param.name
              ..type = param is FunctionParamConfig ? param.funRefer : param.type.refer)),
          ])
          ..constructors.add(
            Constructor((b) => b
              ..constant = true
              ..optionalParameters.addAll(
                buildArgParams(r.parameters),
              )),
          ),
      )
  ];
}

Iterable<Parameter> buildArgParams(List<ParamConfig> parameters) {
  return parameters.map(
    (p) => Parameter(
      (b) {
        b
          ..name = p.getSafeName()
          ..named = true
          ..toThis = true
          ..required = p.isRequired || p.isPositional
          ..defaultTo = p.defaultCode;
        if (p.hasRequired && !p.isRequired) b.annotations.add(requiredAnnotation);
      },
    ),
  );
}
