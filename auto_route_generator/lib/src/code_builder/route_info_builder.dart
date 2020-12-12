import 'package:auto_route_generator/route_config_resolver.dart';
import 'package:code_builder/code_builder.dart';

import 'library_builder.dart';

Class buildRouteInfo(RouteConfig r, RouterConfig router) => Class(
      (b) => b
        ..name = r.routeName
        ..extend = pageRouteType
        ..fields.addAll([
          Field(
            (b) => b
              ..modifier = FieldModifier.constant
              ..name = 'key'
              ..static = true
              ..type = stringRefer
              ..assignment = literalString(r.routeName).code,
          )
        ])
        ..constructors.add(
          Constructor(
            (b) {
              var argSuffix = '';
              if (router.alwaysSuffixArgsWithArg) {
                argSuffix = 'Arg';
              } else if (r.pathParams?.isNotEmpty == true) {
                argSuffix = 'Arg';
              }

              return b
                ..optionalParameters.addAll([
                  ...buildArgParams(r.argParams, argSuffix),
                  if (r.pathParams?.isNotEmpty == true)
                    ...r.pathParams.map(
                      (p) => Parameter((b) {
                        b
                          ..named = true
                          ..name = p.name;
                        if (!p.isOptional) {
                          b.annotations.add(requiredAnnotation);
                        }
                        return b;
                      }),
                    ),
                  if (r.isParent)
                    Parameter((b) => b
                      ..named = true
                      ..name = 'children'
                      ..type = listRefer(pageRouteType)),
                  if (router.usesPathFragments)
                    Parameter(
                      (b) => b
                        ..named = true
                        ..name = "fragment"
                        ..type = stringRefer,
                    ),
                  if (router.usesQueryParams)
                    Parameter(
                      (b) => b
                        ..named = true
                        ..name = "queryParams"
                        ..type = refer('Map<String,dynamic>'),
                    )
                ])
                ..initializers.add(refer('super').call([
                  refer('key')
                ], {
                  'path': literalString(r.pathName),
                  if (r.pathParams?.isNotEmpty == true)
                    'pathParams': literalMap(Map.fromEntries(
                      r.pathParams.map(
                        (p) => MapEntry(
                          p.name,
                          refer(p.name),
                        ),
                      ),
                    )),
                  if (r.argParams?.isNotEmpty == true)
                    'args': refer('${r.className}Args').newInstance(
                      [],
                      {}..addEntries(
                          r.argParams.map((p) => MapEntry(p.name, refer("${p.name}$argSuffix"))),
                        ),
                    ),
                  if (r.isParent) 'children': refer('children'),
                  if (router.usesQueryParams) 'queryParams': refer("queryParams"),
                  if (router.usesPathFragments) 'fragment': refer('fragment')
                }).code);
            },
          ),
        ),
    );

Iterable<Parameter> buildArgParams(List<ParamConfig> argParams, String argSuffix) {
  return argParams.map(
    (p) => Parameter(
      (b) {
        b
          ..name = "${p.name}$argSuffix"
          ..named = true
          ..defaultTo = p.defaultCode
          ..type = p is FunctionParamConfig ? p.funRefer : p.type.refer;
        if (p.isRequired) b.annotations.add(requiredAnnotation);
      },
    ),
  );
}
