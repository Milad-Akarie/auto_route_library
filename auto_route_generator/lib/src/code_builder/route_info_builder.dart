import 'dart:core';

import 'package:auto_route_generator/src/models/resolved_type.dart';
import 'package:code_builder/code_builder.dart';

import '../models/route_config.dart';
import '../models/route_parameter_config.dart';
import '../models/router_config.dart';
import 'library_builder.dart';

const _collectionsImport = 'package:collection/collection.dart';

/// Builds a generic type reference with the given [symbol] and [args]
TypeReference _genericRef(String symbol, List<ResolvedType> args, [String? url]) {
  return TypeReference((b) {
    b
      ..symbol = symbol
      ..url = url
      ..types.addAll(args.map((t) => t.refer));
  });
}

/// Builds a route info class and args class for the given [RouteConfig]
List<Class> buildRouteInfoAndArgs(RouteConfig r, RouterConfig router, DartEmitter emitter) {
  final argsClassRefer = refer('${r.getName(router.replaceInRouteName)}Args');
  final parameters = r.parameters;
  final fragmentParam = parameters.where((p) => p.isUrlFragment).firstOrNull;
  final nonInheritedParameters = parameters.where((p) => !p.isInheritedPathParam).toList();
  final equatableParams = nonInheritedParameters.where((p) => (p is! FunctionParamConfig)).toList();
  final pageInfoRefer = refer('PageInfo', autoRouteImport);
  return [
    Class(
      (b) => b
        ..docs.addAll(['/// generated route for \n/// [${r.pageType?.refer.accept(emitter).toString()}]'])
        ..name = r.getName(router.replaceInRouteName)
        ..extend = TypeReference((b) {
          b
            ..symbol = 'PageRouteInfo'
            ..url = autoRouteImport
            ..types.add(
              (nonInheritedParameters.isNotEmpty) ? argsClassRefer : refer('void'),
            );
        })
        ..fields.addAll([
          Field(
            (b) => b
              ..modifier = FieldModifier.constant
              ..name = 'name'
              ..static = true
              ..type = stringRefer
              ..assignment = literalString(r.getName(router.replaceInRouteName)).code,
          ),
          Field(
            (b) => b
              ..name = 'page'
              ..static = true
              ..type = pageInfoRefer
              ..assignment = pageInfoRefer.newInstance([refer('name')], {'builder': _buildMethod(r, router)}).code,
          ),
        ])
        ..constructors.addAll(
          [
            Constructor(
              (b) {
                b
                  ..constant = parameters.isEmpty
                  ..optionalParameters.addAll([
                    ...buildArgParams(nonInheritedParameters, emitter, toThis: false),
                    Parameter((b) => b
                      ..named = true
                      ..name = 'children'
                      ..type = listRefer(pageRouteType, nullable: true)),
                  ])
                  ..initializers.add(refer('super').call([
                    refer(r.getName(router.replaceInRouteName)).property('name')
                  ], {
                    if (nonInheritedParameters.isNotEmpty)
                      'args': argsClassRefer.call(
                        [],
                        Map.fromEntries(
                          nonInheritedParameters.map(
                            (p) => MapEntry(
                              p.name,
                              refer(p.getSafeName()),
                            ),
                          ),
                        ),
                      ),
                    if (nonInheritedParameters.any((p) => p.isPathParam))
                      'rawPathParams': literalMap(
                        Map.fromEntries(
                          nonInheritedParameters.where((p) => p.isPathParam).map(
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
                    if (fragmentParam != null) 'fragment': refer(fragmentParam.name),
                    'initialChildren': refer('children'),
                    if (!router.argsEquality) 'argsEquality': literalBool(false),
                  }).code);
              },
            ),
          ],
        ),
    ),
    if (nonInheritedParameters.isNotEmpty)
      Class(
        (b) => b
          ..name = argsClassRefer.symbol
          ..fields.addAll([
            ...nonInheritedParameters.map((param) => Field((b) => b
              ..modifier = FieldModifier.final$
              ..name = param.name
              ..type = param is FunctionParamConfig ? param.funRefer : param.type.refer)),
          ])
          ..constructors.add(
            Constructor((b) => b
              ..constant = true
              ..optionalParameters.addAll(
                buildArgParams(nonInheritedParameters, emitter, useSafeName: false),
              )),
          )
          ..methods.addAll([
            Method(
              (b) => b
                ..name = 'toString'
                ..lambda = false
                ..annotations.add(refer('override'))
                ..returns = stringRefer
                ..body = literalString(
                  '${r.getName(router.replaceInRouteName)}Args{${nonInheritedParameters.map((p) => '${p.name}: \$${p.name}').join(', ')}}',
                ).returned.statement,
            ),
            if (router.argsEquality)
              Method(
                (b) => b
                  ..name = 'operator =='
                  ..lambda = false
                  ..annotations.add(refer('override'))
                  ..returns = refer('bool')
                  ..requiredParameters.add(
                    Parameter((b) => b
                      ..name = 'other'
                      ..type = refer('Object')),
                  )
                  ..body = Block(
                    (b) => b
                      ..statements.addAll([
                        Code('if (identical(this, other)) return true;'),
                        Code('if (other is! ${argsClassRefer.symbol}) return false;'),
                        Code('return '),
                        ...[
                          for (final p in equatableParams)
                            if (p.type.isList)
                              _genericRef('ListEquality', p.type.typeArguments, _collectionsImport)
                                  .constInstance([])
                                  .property('equals')
                                  .call([
                                    refer(p.name),
                                    refer('other').property(p.name),
                                  ])
                                  .code
                            else if (p.type.isSet)
                              _genericRef('SetEquality', p.type.typeArguments, _collectionsImport)
                                  .constInstance([])
                                  .property('equals')
                                  .call([
                                    refer(p.name),
                                    refer('other').property(p.name),
                                  ])
                                  .code
                            else if (p.type.isMap)
                              _genericRef('MapEquality', p.type.typeArguments, _collectionsImport)
                                  .constInstance([])
                                  .property('equals')
                                  .call([
                                    refer(p.name),
                                    refer('other').property(p.name),
                                  ])
                                  .code
                            else if (p.type.isIterable)
                              _genericRef('IterableEquality', p.type.typeArguments, _collectionsImport)
                                  .constInstance([])
                                  .property('equals')
                                  .call([
                                    refer(p.name),
                                    refer('other').property(p.name),
                                  ])
                                  .code
                            else
                              Code('${p.name} == other.${p.name}'),
                        ].insertBetween(Code(' && ')),
                        Code(';'),
                      ]),
                  ),
              ),
            if (router.argsEquality)
              Method(
                (b) => b
                  ..name = 'hashCode'
                  ..type = MethodType.getter
                  ..annotations.add(refer('override'))
                  ..returns = refer('int')
                  ..lambda = true
                  ..body = Block(
                    (b) => b.statements.addAll([
                      for (final p in equatableParams)
                        if (p.type.isList)
                          _genericRef('ListEquality', p.type.typeArguments, _collectionsImport)
                              .constInstance([])
                              .property('hash')
                              .call([refer(p.name)])
                              .code
                        else if (p.type.isSet)
                          _genericRef('SetEquality', p.type.typeArguments, _collectionsImport)
                              .constInstance([])
                              .property('hash')
                              .call([refer(p.name)])
                              .code
                        else if (p.type.isMap)
                          _genericRef('MapEquality', p.type.typeArguments, _collectionsImport)
                              .constInstance([])
                              .property('hash')
                              .call([refer(p.name)])
                              .code
                        else if (p.type.isIterable)
                          _genericRef('IterableEquality', p.type.typeArguments, _collectionsImport)
                              .constInstance([])
                              .property('hash')
                              .call([refer(p.name)])
                              .code
                        else
                          Code('${p.name}.hashCode')
                    ].insertBetween(
                      Code(' ^ '),
                    )),
                  ),
              )
          ]),
      )
  ];
}

/// Builds a list of [Parameter]s from the given [parameters]
Iterable<Parameter> buildArgParams(List<ParamConfig> parameters, DartEmitter emitter,
    {bool toThis = true, bool useSafeName = true}) {
  return parameters.map(
    (p) => Parameter(
      (b) {
        Code? defaultCode;
        if (p.defaultValueCode != null) {
          if (p.defaultValueCode!.contains('const')) {
            if (p.defaultValueCode!.contains('[]')) {
              defaultCode = Code('const []');
            } else if (p.defaultValueCode!.contains('{}')) {
              defaultCode = Code('const {}');
            } else {
              defaultCode = Code(
                  'const ${refer(p.defaultValueCode!.replaceAll('const', ''), p.type.import).accept(emitter).toString()}');
            }
          } else {
            defaultCode = refer(p.defaultValueCode!, p.type.import).code;
          }
        }
        b
          ..name = useSafeName ? p.getSafeName() : p.name
          ..named = true
          ..toThis = toThis
          ..required = p.isRequired || p.isPositional
          ..defaultTo = defaultCode;
        if (!toThis) {
          b.type = p is FunctionParamConfig ? p.funRefer : p.type.refer;
        }
      },
    ),
  );
}

Expression _buildMethod(RouteConfig r, RouterConfig router) {
  final useConsConstructor = r.hasConstConstructor && !(r.deferredLoading ?? router.deferredLoading);
  var constructedPage = useConsConstructor ? r.pageType!.refer.constInstance([]) : _getPageInstance(r);

  if (r.hasWrappedRoute == true) {
    constructedPage = refer('WrappedRoute', autoRouteImport).newInstance(
      [],
      {'child': constructedPage},
    );
  }

  if ((r.deferredLoading ?? router.deferredLoading) && r.pageType != null) {
    constructedPage = _getDeferredBuilder(r, constructedPage);
  }
  final inheritedParameters = r.parameters.where((p) => p.isInheritedPathParam);

  final nonInheritedParameters = r.parameters.where((p) => !p.isInheritedPathParam);
  return Method(
    (b) => b
      ..requiredParameters.add(
        Parameter((b) => b.name = 'data'),
      )
      ..body = Block((b) => b.statements.addAll([
            if ((!r.hasUnparsableRequiredArgs) && r.parameters.any((p) => p.isPathParam) ||
                inheritedParameters.isNotEmpty)
              declareFinal('pathParams').assign(refer('data').property('inheritedPathParams')).statement,
            if (!r.hasUnparsableRequiredArgs && r.parameters.any((p) => p.isQueryParam))
              declareFinal('queryParams').assign(refer('data').property('queryParams')).statement,
            if (nonInheritedParameters.isNotEmpty)
              declareFinal('args')
                  .assign(
                    refer('data').property('argsAs').call([], {
                      if (!r.hasUnparsableRequiredArgs)
                        'orElse': Method(
                          (b) => b
                            ..lambda = true
                            ..body = r.pathQueryParams.isEmpty
                                ? refer('${r.getName(router.replaceInRouteName)}Args').constInstance([]).code
                                : refer('${r.getName(router.replaceInRouteName)}Args').newInstance(
                                    [],
                                    Map.fromEntries(
                                      nonInheritedParameters
                                          .where((p) => (p.isPathParam || p.isQueryParam || p.isUrlFragment))
                                          .map(
                                            (p) => MapEntry(
                                              p.name,
                                              _getUrlPartAssignment(p),
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
            constructedPage.returned.statement
          ])),
  ).closure;
}

Expression _getDeferredBuilder(RouteConfig r, Expression page) {
  return TypeReference((b) => b
    ..symbol = 'DeferredWidget'
    ..url = autoRouteImport).newInstance([
    TypeReference((b) => b
      ..symbol = 'loadLibrary'
      ..url = r.pageType!.refer.url),
    Method((b) => b..body = page.code).closure
  ]);
}

Expression _getPageInstance(RouteConfig r) {
  return r.pageType!.refer.newInstance(
    r.positionalParams.map((p) {
      return refer('args').property(p.name);
    }),
    Map.fromEntries(r.namedParams.map(
      (p) => MapEntry(
        p.name,
        p.isInheritedPathParam ? _getUrlPartAssignment(p) : refer('args').property(p.name),
      ),
    )),
  );
}

Expression _getUrlPartAssignment(ParamConfig p) {
  if (p.isPathParam) {
    return refer('pathParams').property(p.getterMethodName).call([
      literalString(p.paramName),
      if (p.defaultValueCode != null) refer(p.defaultValueCode!),
    ]);
  } else if (p.isQueryParam) {
    return refer('queryParams').property(p.getterMethodName).call([
      literalString(p.paramName),
      if (p.defaultValueCode != null) refer(p.defaultValueCode!),
    ]);
  } else {
    return refer('data').property('fragment');
  }
}

extension _IterableX<T> on Iterable<T> {
  Iterable<T> insertBetween(T element) sync* {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      yield iterator.current;
      while (iterator.moveNext()) {
        yield element;
        yield iterator.current;
      }
    }
  }
}
