import 'package:auto_route_generator/route_config_resolver.dart';
import 'package:code_builder/code_builder.dart';

import 'library_builder.dart';

Class buildRouteInfo(RouteConfig r, RouterConfig router) => Class(
      (b) => b
        ..name = r.routeName
        ..extend = pageRouteType
        ..fields.addAll([
          if (r.parameters?.isNotEmpty == true)
            ...r.parameters.map((param) => Field((b) => b
              ..modifier = FieldModifier.final$
              ..name = param.name
              ..type = param is FunctionParamConfig
                  ? param.funRefer
                  : param.type.refer)),
          Field(
            (b) => b
              ..modifier = FieldModifier.constant
              ..name = 'name'
              ..static = true
              ..type = stringRefer
              ..assignment = literalString(r.routeName).code,
          )
        ])
        ..constructors.addAll(
          [
            Constructor(
              (b) {
                return b
                  ..constant = (r.parameters == null)
                  ..optionalParameters.addAll([
                    if (r.parameters?.isNotEmpty == true)
                      ...buildArgParams(r.parameters),
                    if (r.isParent)
                      Parameter((b) => b
                        ..named = true
                        ..name = 'children'
                        ..type = listRefer(pageRouteType)),
                  ])
                  ..initializers.add(refer('super').call([
                    refer('name')
                  ], {
                    'path': literalString(r.pathName),
                    if (r.pathParams?.isNotEmpty == true)
                      'params': literalMap(
                        Map.fromEntries(
                          r.pathParams.map(
                            (p) => MapEntry(
                              p.name,
                              refer(p.name),
                            ),
                          ),
                        ),
                      ),
                    if (r.parameters?.any((p) => p.isQueryParam) == true)
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
            Constructor(
              (b) {
                b
                  ..name = 'fromMatch'
                  ..initializers.addAll([
                    if (r.parameters?.isNotEmpty == true)
                      ...r.parameters.map((p) =>
                          refer(p.name).assign(getParamAssignment(p)).code),
                    refer('super')
                        .newInstanceNamed('fromMatch', [refer('match')]).code
                  ]);
                b.requiredParameters.add(
                  Parameter(
                    (b) => b
                      ..name = 'match'
                      ..type = refer("RouteMatch", autoRouteImport),
                  ),
                );
                return b;
              },
            )
          ],
        ),
    );

Iterable<Parameter> buildArgParams(List<ParamConfig> parameters) {
  return parameters.map(
    (p) => Parameter(
      (b) {
        b
          ..name = p.getSafeName()
          ..named = true
          ..toThis = true
          ..required = p.isRequired
          ..defaultTo = p.defaultCode;
        if (p.hasRequired && !p.isRequired)
          b.annotations.add(requiredAnnotation);
        return b;
      },
    ),
  );
}

Expression getParamAssignment(ParamConfig p) {
  if (p.isPathParam) {
    return refer('match')
        .property('pathParams')
        .property(p.getterMethodName)
        .call([
      literalString(p.paramName),
      if (p.defaultValueCode != null) refer(p.defaultValueCode),
    ]);
  } else if (p.isQueryParam) {
    return refer('match')
        .property('queryParams')
        .property(p.getterMethodName)
        .call([
      literalString(p.paramName),
      if (p.defaultValueCode != null) refer(p.defaultValueCode),
    ]);
  } else {
    return refer('null');
  }
}
