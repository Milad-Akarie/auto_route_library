import 'package:auto_route_generator/route_config_resolver.dart';
import 'package:code_builder/code_builder.dart';

import 'library_builder.dart';

Class buildRouteInfo(RouteConfig r) => Class(
      (b) => b
        ..name = r.routeName
        ..extend = pageRouteType
        ..fields.addAll([
          Field((b) => b
            ..modifier = FieldModifier.constant
            ..name = 'key'
            ..static = true
            ..type = stringRefer
            ..assignment = Code("'${r.pathName}'")),
        ])
        ..constructors.add(
          Constructor(
            (b) => b
              ..optionalParameters.addAll([
                ...buildArgParams(r.argParams),
                if (r.isParent)
                  Parameter((b) => b
                    ..name = 'children'
                    ..type = listRefer(pageRouteType)),
                Parameter(
                  (b) => b
                    ..name = "fragment"
                    ..type = stringRefer,
                ),
                Parameter(
                  (b) => b
                    ..name = "queryParams"
                    ..type = refer('Map<String,dynamic>'),
                )
              ])
              ..initializers.add(refer('super').call([
                refer('key')
              ], {
                if (r.argParams?.isNotEmpty == true)
                  'args': refer('${r.className}Args').newInstance(
                    [],
                    {}..addEntries(
                        r.argParams.map((p) => MapEntry(p.name, refer(p.name))),
                      ),
                  ),
                if (r.isParent) 'children': refer('children'),
                'queryParams': refer("queryParams"),
                'fragment': refer('fragment')
              }).code),
          ),
        ),
    );

Iterable<Parameter> buildArgParams(List<ParamConfig> argParams) {
  return argParams.map(
    (p) => Parameter(
      (b) {
        b
          ..name = p.name
          ..named = true
          ..defaultTo = p.defaultCode
          ..type = p is FunctionParamConfig ? p.funRefer : p.type.refer;
        if (p.isRequired) b.annotations.add(requiredAnnotation);
      },
    ),
  );
}
