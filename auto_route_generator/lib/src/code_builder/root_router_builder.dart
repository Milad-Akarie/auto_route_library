import 'package:code_builder/code_builder.dart';

import '../../utils.dart';
import '../models/route_config.dart';
import '../models/route_parameter_config.dart';
import '../models/router_config.dart';
import 'library_builder.dart';

Class buildRouterConfig(RouterConfig router, List<RouteConfig> routes) => Class(
      (b) => b
        ..name =
            '${router.usesPartBuilder ? '_' : ''}\$${router.routerClassName}'
        ..abstract = true
        ..extend = refer('RootStackRouter', autoRouteImport)
        ..fields.addAll([buildPagesMap(routes, router)])
        ..constructors.addAll([
          Constructor(
            (b) => b
              ..optionalParameters.add(
                Parameter(
                  (b) => b
                    ..name = 'navigatorKey'
                    ..type = TypeReference(
                      (b) => b
                        ..url = materialImport
                        ..symbol = 'GlobalKey'
                        ..isNullable = true
                        ..types.add(
                          refer('NavigatorState', materialImport),
                        ),
                    ),
                ),
              )
              ..initializers.add(
                refer('super').call([
                  refer('navigatorKey'),
                ]).code,
              ),
          ),
        ]),
    );

Field buildPagesMap(List<RouteConfig> routes, RouterConfig router) {
  return Field((b) => b
    ..name = "pagesMap"
    ..modifier = FieldModifier.final$
    ..annotations.add(refer('override'))
    ..type = TypeReference(
      (b) => b
        ..symbol = 'Map'
        ..types.addAll([
          stringRefer,
          refer('PageFactory', autoRouteImport),
        ]),
    )
    ..assignment = literalMap(Map.fromEntries(
      routes.distinctBy((e) => e.getName(router.replaceInRouteName)).map(
            (r) => MapEntry(
              refer(r.getName(router.replaceInRouteName)).property('name'),
              buildMethod(r, router),
            ),
          ),
    )).code);
}

Spec buildMethod(RouteConfig r, RouterConfig router) {
  final useConsConstructor =
      r.hasConstConstructor && !(r.deferredLoading ?? router.deferredLoading);
  var constructedPage = useConsConstructor
      ? r.pageType!.refer.constInstance([])
      : getPageInstance(r);

  if (r.hasWrappedRoute == true) {
    constructedPage = refer('WrappedRoute', autoRouteImport).newInstance(
      [],
      {'child': constructedPage},
    );
  }

  if ((r.deferredLoading ?? router.deferredLoading) && r.pageType != null) {
    constructedPage = getDeferredBuilder(r, constructedPage);
  }
  final inheritedParameters = r.parameters.where((p) => p.isInheritedPathParam);

  final nonInheritedParameters =
      r.parameters.where((p) => !p.isInheritedPathParam);
  return Method(
    (b) => b
      ..requiredParameters.add(
        Parameter((b) => b.name = 'routeData'),
      )
      ..body = Block((b) => b.statements.addAll([
            if ((!r.hasUnparsableRequiredArgs) &&
                    r.parameters.any((p) => p.isPathParam) ||
                inheritedParameters.isNotEmpty)
              declareFinal('pathParams')
                  .assign(refer('routeData').property('inheritedPathParams'))
                  .statement,
            if (!r.hasUnparsableRequiredArgs &&
                r.parameters.any((p) => p.isQueryParam))
              declareFinal('queryParams')
                  .assign(refer('routeData').property('queryParams'))
                  .statement,
            if (nonInheritedParameters.isNotEmpty)
              declareFinal('args')
                  .assign(
                    refer('routeData').property('argsAs').call([], {
                      if (!r.hasUnparsableRequiredArgs)
                        'orElse': Method(
                          (b) => b
                            ..lambda = true
                            ..body = r.pathQueryParams.isEmpty
                                ? refer('${r.getName(router.replaceInRouteName)}Args')
                                    .constInstance([]).code
                                : refer('${r.getName(router.replaceInRouteName)}Args')
                                    .newInstance(
                                    [],
                                    Map.fromEntries(
                                      nonInheritedParameters
                                          .where((p) =>
                                              (p.isPathParam || p.isQueryParam))
                                          .map(
                                            (p) => MapEntry(
                                              p.name,
                                              getUrlParamAssignment(p),
                                            ),
                                          ),
                                    ),
                                  ).code,
                        ).closure
                    }, [
                      refer('${r.getName(router.replaceInRouteName)}Args'),
                    ]),
                  )
                  .statement,
            TypeReference(
              (b) => b
                ..symbol = 'AutoRoutePage'
                ..url = autoRouteImport
                ..types.add(r.returnType?.refer ?? refer('dynamic')),
            )
                .newInstance(
                  [],
                  {
                    'routeData': refer('routeData'),
                    'child': constructedPage,
                  },
                )
                .returned
                .statement
          ])),
  ).closure;
}

Expression getDeferredBuilder(RouteConfig r, Expression page) {
  return TypeReference((b) => b
    ..symbol = 'DeferredWidget'
    ..url = autoRouteImport).newInstance([
    TypeReference((b) => b
      ..symbol = 'loadLibrary'
      ..url = r.pageType!.refer.url),
    Method((b) => b..body = page.code).closure
  ]);
}

Expression getPageInstance(RouteConfig r) {
  return r.pageType!.refer.newInstance(
    r.positionalParams.map((p) {
      return refer('args').property(p.name);
    }),
    Map.fromEntries(r.namedParams.map(
      (p) => MapEntry(
        p.name,
        p.isInheritedPathParam
            ? getUrlParamAssignment(p)
            : refer('args').property(p.name),
      ),
    )),
  );
}

Expression getUrlParamAssignment(ParamConfig p) {
  if (p.isPathParam) {
    return refer('pathParams').property(p.getterMethodName).call([
      literalString(p.paramName),
      if (p.defaultValueCode != null) refer(p.defaultValueCode!),
    ]);
  } else {
    return refer('queryParams').property(p.getterMethodName).call([
      literalString(p.paramName),
      if (p.defaultValueCode != null) refer(p.defaultValueCode!),
    ]);
  }
}
