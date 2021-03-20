import 'package:code_builder/code_builder.dart';

import '../../utils.dart';
import '../models/importable_type.dart';
import '../models/route_config.dart';
import '../models/route_parameter_config.dart';
import '../models/router_config.dart';
import 'library_builder.dart';

const _routeConfigType = Reference("RouteConfig", autoRouteImport);

Class buildRouterConfig(RouterConfig router, Set<ImportableType> guards,
        List<RouteConfig> routes) =>
    Class((b) => b
      ..name = router.routerClassName
      ..extend = refer('RootStackRouter', autoRouteImport)
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
            ..returns = listRefer(_routeConfigType)
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
                ..required = true
                ..toThis = true),
            ),
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
          stringRefer,
          refer('PageFactory', autoRouteImport),
        ]),
    )
    ..assignment = literalMap(Map.fromEntries(
      routes.where((r) => r.routeType != RouteType.redirect).map(
            (r) =>
                MapEntry(refer(r.routeName).property('name'), buildMethod(r)),
          ),
    )).code);
}

Method buildMethod(RouteConfig r) {
  return Method(
    (b) => b
      ..requiredParameters.add(
        Parameter((b) => b.name = 'entry'),
      )
      ..body = Block(
        (b) => b.statements.addAll([
          if (!r.hasUnparsableRequiredArags &&
              r.parameters.any((p) => p.isPathParam))
            refer('entry')
                .property('routeData')
                .property('pathParams')
                .assignVar('pathParams')
                .statement,
          if (!r.hasUnparsableRequiredArags &&
              r.parameters.any((p) => p.isQueryParam))
            refer('entry')
                .property('routeData')
                .property('queryParams')
                .assignVar('queryParams')
                .statement,
          if (r.parameters.isNotEmpty)
            refer('entry')
                .property('routeData')
                .property('argsAs')
                .call([], {
                  if (!r.hasUnparsableRequiredArags)
                    'orElse': Method(
                      (b) => b.body = refer('${r.routeName}Args').newInstance(
                        [],
                        Map.fromEntries(r.parameters
                            .where((p) => p.isPathParam || p.isQueryParam)
                            .map(
                              (p) => MapEntry(
                                p.name,
                                getUrlParamAssignment(p),
                              ),
                            )),
                      ).code,
                    ).closure
                }, [
                  refer('${r.routeName}Args'),
                ])
                .assignVar('args')
                .statement,
          refer(r.pageTypeName, autoRouteImport)
              .newInstance(
                [],
                {
                  'entry': refer('entry'),
                  'child': r.hasConstConstructor
                      ? r.pageType!.refer.constInstance([])
                      : r.pageType!.refer.newInstance(
                          r.positionalParams
                              .map((p) => refer('args').property(p.name)),
                          Map.fromEntries(r.namedParams.map(
                            (p) => MapEntry(
                              p.name,
                              refer('args').property(p.name),
                            ),
                          )),
                        ),
                  if (r.maintainState == false)
                    'maintainState': literalBool(false),
                  if (r.fullscreenDialog == true)
                    'fullscreenDialog': literalBool(true),
                  if ((r.routeType == RouteType.cupertino ||
                          r.routeType == RouteType.adaptive) &&
                      r.cupertinoNavTitle != null)
                    'title': literalString(r.cupertinoNavTitle),
                  if (r.routeType == RouteType.custom) ...{
                    if (r.customRouteBuilder != null)
                      'customRouteBuilder': r.customRouteBuilder!.refer,
                    if (r.transitionBuilder != null)
                      'transitionsBuilder': r.transitionBuilder!.refer,
                    if (r.durationInMilliseconds != null)
                      'durationInMilliseconds':
                          literalNum(r.durationInMilliseconds),
                    if (r.reverseDurationInMilliseconds != null)
                      'reverseDurationInMilliseconds':
                          literalNum(r.reverseDurationInMilliseconds),
                    if (r.customRouteOpaque != null)
                      'opaque': literalBool(r.customRouteOpaque),
                    if (r.customRouteBarrierDismissible != null)
                      'barrierDismissible':
                          literalBool(r.customRouteBarrierDismissible),
                    if (r.customRouteBarrierLabel != null)
                      'barrierLabel': literalString(r.customRouteBarrierLabel),
                  }
                },
              )
              .returned
              .statement
        ]),
      ),
  );
}

Expression getUrlParamAssignment(ParamConfig p) {
  if (p.isPathParam) {
    return refer('pathParams').property(p.getterMethodName).call([
      literalString(p.paramName),
      if (p.defaultValueCode != null) refer(p.defaultValueCode),
    ]);
  } else {
    return refer('queryParams').property(p.getterMethodName).call([
      literalString(p.paramName),
      if (p.defaultValueCode != null) refer(p.defaultValueCode),
    ]);
  }
}

Iterable<Object> buildRoutes(List<RouteConfig> routes) => routes.map(
      (r) {
        return _routeConfigType.newInstance(
          [
            if (r.routeType == RouteType.redirect)
              literalString('${r.pathName}#redirect')
            else
              refer(r.routeName).property('name'),
          ],
          {
            'path': literalString(r.pathName),
            if (r.redirectTo != null) 'redirectTo': literalString(r.redirectTo),
            if (r.fullMatch == true) 'fullMatch': literalBool(true),
            if (r.usesTabsRouter == true) 'usesTabsRouter': literalBool(true),
            if (r.guards.isNotEmpty)
              'guards': literalList(r.guards
                  .map(
                    (g) => refer(
                      toLowerCamelCase(g.toString()),
                    ),
                  )
                  .toList(growable: false)),
            if (r.childRouterConfig != null)
              'children': literalList(buildRoutes(r.childRouterConfig!.routes))
          },
        );
      },
    );
