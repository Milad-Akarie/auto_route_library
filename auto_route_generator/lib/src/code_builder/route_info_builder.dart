import 'package:code_builder/code_builder.dart';

import '../models/route_config.dart';
import '../models/route_parameter_config.dart';
import '../models/router_config.dart';
import 'library_builder.dart';

List<Class> buildRouteInfoAndArgs(
    RouteConfig r, RouterConfig router, DartEmitter emitter) {
  final argsClassRefer = refer('${r.routeName}Args');
  final parameters =
      r.parameters.where((p) => !p.isInheritedPathParam).toList();
  return [
    Class(
      (b) => b
        ..docs.addAll([
          '/// generated route for \n/// [${r.pageType?.refer.accept(emitter).toString()}]'
        ])
        ..name = r.routeName
        ..extend = TypeReference((b) {
          b
            ..symbol = 'PageRouteInfo'
            ..url = autoRouteImport;
          if (parameters.isNotEmpty) b.types.add(argsClassRefer);
          // adds `void` type to be `strong-mode` compliant
          if (parameters.isEmpty) b.types.add(refer('void'));
        })
        ..fields.add(Field(
          (b) => b
            ..modifier = FieldModifier.constant
            ..name = 'name'
            ..static = true
            ..type = stringRefer
            ..assignment = literalString(r.routeName).code,
        ))
        ..constructors.add(
          Constructor(
            (b) {
              b
                ..constant = parameters.isEmpty
                ..optionalParameters.addAll([
                  ...buildArgParams(r.parameters, emitter, toThis: false),
                  if (r.isParent)
                    Parameter((b) => b
                      ..named = true
                      ..name = 'children'
                      ..type = listRefer(pageRouteType, nullable: true)),
                ])
                ..initializers.add(refer('super').call([
                  refer(r.routeName).property('name')
                ], {
                  'path': literalString(r.pathName),
                  if (parameters.isNotEmpty)
                    'args': argsClassRefer.call(
                      [],
                      Map.fromEntries(
                        parameters.map(
                          (p) => MapEntry(
                            p.name,
                            refer(p.name),
                          ),
                        ),
                      ),
                    ),
                  if (parameters.any((p) => p.isPathParam))
                    'rawPathParams': literalMap(
                      Map.fromEntries(
                        parameters.where((p) => p.isPathParam).map(
                              (p) => MapEntry(
                                p.paramName,
                                refer(p.name),
                              ),
                            ),
                      ),
                    ),
                  if (parameters.any((p) => p.isQueryParam))
                    'rawQueryParams': literalMap(
                      Map.fromEntries(
                        parameters.where((p) => p.isQueryParam).map(
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
    if (parameters.isNotEmpty)
      Class(
        (b) => b
          ..name = argsClassRefer.symbol
          ..fields.addAll([
            ...parameters.map((param) => Field((b) => b
              ..modifier = FieldModifier.final$
              ..name = param.name
              ..type = param is FunctionParamConfig
                  ? param.funRefer
                  : param.type.refer)),
          ])
          ..constructors.add(
            Constructor((b) => b
              ..constant = true
              ..optionalParameters.addAll(
                buildArgParams(r.parameters, emitter),
              )),
          )
          ..methods.add(
            Method(
              (b) => b
                ..name = 'toString'
                ..lambda = false
                ..annotations.add(refer('override'))
                ..returns = stringRefer
                ..body = literalString(
                  '${r.routeName}Args{${parameters.map((p) => '${p.name}: \$${p.name}').join(', ')}}',
                ).returned.statement,
            ),
          ),
      )
  ];
}

Iterable<Parameter> buildArgParams(
    List<ParamConfig> parameters, DartEmitter emitter,
    {bool toThis = true}) {
  return parameters.where((p) => !p.isInheritedPathParam).map(
        (p) => Parameter(
          (b) {
            var defaultCode;
            if (p.defaultValueCode != null) {
              if (p.defaultValueCode!.contains('const')) {
                defaultCode = Code(
                    'const ${refer(p.defaultValueCode!.replaceAll('const', ''), p.type.import).accept(emitter).toString()}');
              } else {
                defaultCode = refer(p.defaultValueCode!, p.type.import).code;
              }
            }
            b
              ..name = p.getSafeName()
              ..named = true
              ..toThis = toThis
              ..required = p.isRequired || p.isPositional
              ..defaultTo = defaultCode;
            if (!toThis)
              b.type = p is FunctionParamConfig ? p.funRefer : p.type.refer;
          },
        ),
      );
}
