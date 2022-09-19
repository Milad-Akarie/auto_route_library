import 'package:code_builder/code_builder.dart';

import '../../utils.dart';
import '../models/importable_type.dart';
import '../models/route_config.dart';
import '../models/route_parameter_config.dart';
import '../models/router_config.dart';
import 'library_builder.dart';

const _routeConfigType = Reference("RouteConfig", autoRouteImport);

Class buildRouterConfig(RouterConfig router, Set<ResolvedType> guards, List<RouteConfig> routes) => Class((b) => b
  ..name = router.routerClassName
  ..extend = refer('RootStackRouter', autoRouteImport)
  ..fields.addAll([
    ...guards.map((g) => Field((b) => b
      ..modifier = FieldModifier.final$
      ..name = toLowerCamelCase(g.name)
      ..type = g.refer)),
    buildPagesMap(routes, router.deferredLoading)
  ])
  ..methods.add(
    Method(
      (b) => b
        ..type = MethodType.getter
        ..name = 'routes'
        ..annotations.add(refer('override'))
        ..returns = listRefer(_routeConfigType)
        ..body = literalList(buildRoutes(router.routes)).code,
    ),
  )
  ..constructors.add(
    Constructor((b) => b
      ..optionalParameters.addAll([
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
        ...guards.map(
          (g) => Parameter((b) => b
            ..name = toLowerCamelCase(g.name)
            ..named = true
            ..required = true
            ..toThis = true),
        ),
      ])
      ..initializers.add(refer('super').call([
        refer('navigatorKey'),
      ]).code)),
    // ),
  ));

Field buildPagesMap(List<RouteConfig> routes, bool deferredLoading) {
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
      routes.where((r) => r.routeType != RouteType.redirect).distinctBy((e) => e.routeName).map(
            (r) => MapEntry(
              refer(r.routeName).property('name'),
              buildMethod(r, deferredLoading),
            ),
          ),
    )).code);
}

Spec buildMethod(RouteConfig r, bool deferredLoading) {
  final useConsConstructor = r.hasConstConstructor && !(r.deferredLoading ?? deferredLoading);
  var constructedPage = useConsConstructor ? r.pageType!.refer.constInstance([]) : getPageInstance(r);

  if (r.hasWrappedRoute == true) {
    constructedPage = refer('WrappedRoute', autoRouteImport).newInstance(
      [],
      {'child': constructedPage},
    );
  }

  if ((r.deferredLoading ?? deferredLoading) && r.pageType != null) {
    constructedPage = getDeferredBuilder(r, constructedPage);
  }

  return Method(
    (b) => b
      ..requiredParameters.add(
        Parameter((b) => b.name = 'routeData'),
      )
      ..body = Block((b) => b.statements.addAll([
            if ((!r.hasUnparsableRequiredArgs || r.parameters.any((p) => p.isInheritedPathParam)) && r.parameters.any((p) => p.isPathParam))
              refer('routeData').property('inheritedPathParams').assignFinal('pathParams').statement,
            if (!r.hasUnparsableRequiredArgs && r.parameters.any((p) => p.isQueryParam))
              refer('routeData').property('queryParams').assignFinal('queryParams').statement,
            if (r.parameters.where((p) => !p.isInheritedPathParam).isNotEmpty)
              refer('routeData')
                  .property('argsAs')
                  .call([], {
                    if (!r.hasUnparsableRequiredArgs)
                      'orElse': Method(
                        (b) => b
                          ..lambda = true
                          ..body = r.pathQueryParams.isEmpty
                              ? refer('${r.routeName}Args').constInstance([]).code
                              : refer('${r.routeName}Args').newInstance(
                                  [],
                                  Map.fromEntries(
                                    r.parameters.where((p) => (p.isPathParam || p.isQueryParam) && !p.isInheritedPathParam).map(
                                          (p) => MapEntry(
                                            p.name,
                                            getUrlParamAssignment(p),
                                          ),
                                        ),
                                  ),
                                ).code,
                      ).closure
                  }, [
                    refer('${r.routeName}Args'),
                  ])
                  .assignFinal('args')
                  .statement,
            TypeReference(
              (b) => b
                ..symbol = r.pageTypeName
                ..url = autoRouteImport
                ..types.add(r.returnType?.refer ?? refer('dynamic')),
            )
                .newInstance(
                  [],
                  {
                    'routeData': refer('routeData'),
                    'child': constructedPage,
                    if (r.maintainState == false) 'maintainState': literalBool(false),
                    if (r.fullscreenDialog == true) 'fullscreenDialog': literalBool(true),
                    if ((r.routeType == RouteType.cupertino || r.routeType == RouteType.adaptive) && r.cupertinoNavTitle != null)
                      'title': literalString(r.cupertinoNavTitle!),
                    if (r.routeType == RouteType.custom) ...{
                      if (r.customRouteBuilder != null) 'customRouteBuilder': r.customRouteBuilder!.refer,
                      if (r.transitionBuilder != null) 'transitionsBuilder': r.transitionBuilder!.refer,
                      if (r.durationInMilliseconds != null) 'durationInMilliseconds': literalNum(r.durationInMilliseconds!),
                      if (r.reverseDurationInMilliseconds != null)
                        'reverseDurationInMilliseconds': literalNum(r.reverseDurationInMilliseconds!),
                      if (r.customRouteOpaque != null) 'opaque': literalBool(r.customRouteOpaque!),
                      if (r.customRouteBarrierDismissible != null) 'barrierDismissible': literalBool(r.customRouteBarrierDismissible!),
                      if (r.customRouteBarrierLabel != null) 'barrierLabel': literalString(r.customRouteBarrierLabel!),
                      if (r.customRouteBarrierColor != null) 'barrierColor': literal(r.customRouteBarrierColor!),
                    }
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
      return p.isInheritedPathParam ? getUrlParamAssignment(p) : refer('args').property(p.name);
    }),
    Map.fromEntries(r.namedParams.map(
      (p) => MapEntry(
        p.name,
        p.isInheritedPathParam ? getUrlParamAssignment(p) : refer('args').property(p.name),
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

Iterable<Object> buildRoutes(List<RouteConfig> routes, {Reference? parent}) => routes.map(
      (r) {
        return _routeConfigType.newInstance(
          [
            if (r.routeType == RouteType.redirect) literalString('${r.pathName}#redirect') else refer(r.routeName).property('name'),
          ],
          {
            'path': literalString(r.pathName),
            if (parent != null) 'parent': parent.property('name'),
            if (r.meta.isNotEmpty)
              'meta': literalMap({
                for (final metaEntry in r.meta) literalString(metaEntry.key): _getLiteralValue(metaEntry),
              }, stringRefer, refer('dynamic')),
            if (r.redirectTo != null) 'redirectTo': literalString(r.redirectTo!),
            if (r.fullMatch == true) 'fullMatch': literalBool(true),
            if (r.usesPathAsKey == true) 'usesPathAsKey': literalBool(true),
            if (r.deferredLoading == true) 'deferredLoading': literalBool(true),
            if (r.guards.isNotEmpty)
              'guards': literalList(r.guards
                  .map(
                    (g) => refer(
                      toLowerCamelCase(g.toString()),
                    ),
                  )
                  .toList(growable: false)),
            if (r.childRouterConfig != null)
              'children': literalList(
                buildRoutes(
                  r.childRouterConfig!.routes,
                  parent: refer(r.routeName),
                ),
              )
          },
        );
      },
    );

Expression _getLiteralValue(MetaEntry<dynamic> metaEntry) {
  switch (metaEntry.type) {
    case 'String':
      return literalString(metaEntry.value);
    case 'int':
      return literalNum(metaEntry.value);
    case 'double':
      return literalNum(metaEntry.value);
    case 'bool':
      return literalBool(metaEntry.value);
    default:
      return literal(metaEntry.value);
  }
}
