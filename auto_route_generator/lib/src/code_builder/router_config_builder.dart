import 'package:auto_route_generator/import_resolver.dart';
import 'package:auto_route_generator/route_config_resolver.dart';
import 'package:auto_route_generator/utils.dart';
import 'package:code_builder/code_builder.dart';

import 'library_builder.dart';

const _routeRefType = Reference("RouteDef", autoRouteImport);

Class buildRouterConfig(RouterConfig router, List<ImportableType> guards, List<RouteConfig> routes) => Class((b) => b
  ..name = router.routerClassName
  ..extend = refer('AutoRouterConfig', autoRouteImport)
  ..fields.addAll([
    ...guards.map((g) => Field((b) => b
      ..modifier = FieldModifier.final$
      ..name = toLowerCamelCase(g.name)
      ..type = g.refer)),
    buildPagesMap(routes)
  ])
  ..methods.add(
    Method(
      (b) => b
        ..type = MethodType.getter
        ..name = 'routes'
        ..annotations.add(refer('override'))
        ..returns = listRefer(_routeRefType)
        ..body = literalList(buildRoutes(router.routes)).code,
    ),
  )
  ..constructors.add(
    Constructor((b) => b
      ..optionalParameters.addAll([
        ...guards.map(
          (g) => Parameter((b) => b
            ..name = toLowerCamelCase(g.name)
            ..named = true
            ..toThis = true
            ..annotations.add(requiredAnnotation)),
        ),
        Parameter(
          (b) => b
            ..name = 'initialDeepLink'
            ..type = refer("String"),
        ),
        Parameter(
          (b) => b
            ..name = 'initialRoutes'
            ..type = listRefer(pageRouteType),
        )
      ])
      ..initializers.addAll([
        ...guards.map((g) => refer('assert').call([
              refer(toLowerCamelCase(g.toString())).notEqualTo(refer('null')),
            ]).code),
        refer('super').call([], {
          'initialDeepLink': refer('initialDeepLink'),
          'initialRoutes': refer('initialRoutes'),
        }).code
      ])),
    // ),
  ));

Field buildPagesMap(List<RouteConfig> routes) {
  return Field((b) => b
    ..name = "pagesMap"
    ..modifier = FieldModifier.final$
    ..annotations.add(refer('override'))
    ..type = TypeReference(
      (b) => b
        ..symbol = 'Map'
        ..types.addAll([
          refer('Type'),
          refer('PageFactory', autoRouteImport),
        ]),
    )
    ..assignment = literalMap(Map.fromEntries(
      routes.map(
        (r) => MapEntry(r.pageType.refer, buildMethod(r)),
      ),
    )).code);
}

// @override
// final pagesMap = <String, PageFactory>{
// HomePageRoute.key: (data) {
// return XMaterialPage(
// data: data,
// builder: HomePage(),
// );
// },

Method buildMethod(RouteConfig r) {
  return Method(
    (b) => b
      ..requiredParameters.add(
        Parameter((b) => b.name = 'data'),
      )
      ..body = Block(
        (b) => b.statements.addAll([
          if (r.parameters?.isNotEmpty == true)
            refer('data.getArgs')
                .call([], {
                  if (!r.argParams.any((p) => p.isRequired || p.isPositional))
                    'orElse': Method(
                      (b) => b.body = refer('${r.className}Args').constInstance([]).code,
                    ).closure,
                }, [
                  refer('${r.className}Args')
                ])
                .assignVar('args')
                .statement,
          refer(r.pageTypeName, autoRouteImport)
              .newInstance(
                [],
                {
                  'data': refer('data'),
                  'child': r.hasConstConstructor
                      ? r.pageType.refer.constInstance([])
                      : r.pageType.refer.newInstance(
                          r.positionalParams.map(getParamAssignment),
                          Map.fromEntries(r.optionalParams.map(
                            (p) => MapEntry(
                              p.name,
                              getParamAssignment(p),
                            ),
                          )),
                        ),
                },
              )
              .returned
              .statement
        ]),
      ),
  );
}

Expression getParamAssignment(ParamConfig p) {
  if (p.isPathParam) {
    return refer('data').property('pathParams').property(p.methodName).call([
      literalString(p.name),
      if (p.defaultValueCode != null) refer(p.defaultValueCode),
    ]);
  } else if (p.isQueryParam) {
    return refer('data').property('queryParams').property(p.methodName).call([
      literalString(p.name),
      if (p.defaultValueCode != null) refer(p.defaultValueCode),
    ]);
  } else {
    var ref = refer('args').property(p.name);
    if (p.defaultValueCode != null) {
      return ref.ifNullThen(refer(p.defaultValueCode));
    }
    return ref;
  }
}

Iterable<Object> buildRoutes(List<RouteConfig> routes) {
  return routes
      .map(
        (r) => _routeRefType.newInstance([
          refer(r.routeName).property('key'),
        ], {
          'page': r.pageType.refer,
          if (r.guards?.isNotEmpty == true)
            'guards': literalList(r.guards
                .map(
                  (g) => refer(
                    toLowerCamelCase(g.toString()),
                  ),
                )
                .toList(growable: false)),
          if (r.routerConfig != null) 'children': literalList(buildRoutes(r.routerConfig.routes))
        }),
      )
      .toList(growable: false);
}
