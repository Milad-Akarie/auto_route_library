import 'dart:core';

import 'package:auto_route_generator/src/code_builder/emit_source.dart';
import 'package:auto_route_generator/src/code_builder/iterable_x.dart';
import 'package:auto_route_generator/src/code_builder/library_builder.dart';
import 'package:auto_route_generator/src/models/param_config.dart';
import 'package:auto_route_generator/src/models/resolved_type.dart';
import 'package:auto_route_generator/src/models/route_config.dart';
import 'package:auto_route_generator/src/models/router_config.dart';
import 'package:code_builder/code_builder.dart';

const _kCollectionsImport = 'package:collection/collection.dart';

/// A string literal of [value] as it is: unlike [literalString], a `$` in
/// it, as in a name such as `venue$id`, is escaped instead of read as an
/// interpolation.
Expression _plainString(String value) => literalString(_escapeDollar(value));

/// The interpolation of the variable [name] in a string literal, braced
/// when [name] holds a `$`, which would otherwise start an interpolation of
/// its own.
String _interpolation(String name) =>
    name.contains(r'$') ? '\${$name}' : '\$$name';

/// [value] with each `$` escaped, to stand for itself in a string literal.
String _escapeDollar(String value) => value.replaceAll(r'$', r'\$');

/// Builds a generic type reference with the given [symbol] and [args]
TypeReference _genericRef(String symbol, List<ResolvedType> args, String url) {
  return TypeReference((b) {
    b
      ..symbol = symbol
      ..url = url
      ..types.addAll(args.map((t) => t.refer));
  });
}

/// Builds a route info class and args class for the given [RouteConfig]
List<Class> buildRouteInfoAndArgs(
  RouteConfig r,
  RouterConfig router,
  DartEmitter emitter,
) {
  final argsClassRefer = refer('${r.getName(router.replaceInRouteName)}Args');
  // A generic route's args carry its type arguments, which build its page.
  final typeArguments = r.typeParameters.map((t) => refer(t.name));
  final typedArgsClassRefer = TypeReference(
    (b) => b
      ..symbol = argsClassRefer.symbol
      ..types.addAll(typeArguments),
  );
  final parameters = r.parameters;
  final fragmentParam = parameters.where((p) => p.isUrlFragment).firstOrNull;
  final nonInheritedParameters = parameters
      .where((p) => !p.isInheritedPathParam)
      .toList();
  final equatableParams = nonInheritedParameters
      .where((p) => p is! FunctionParamConfig)
      .toList();
  final hasArgs = nonInheritedParameters.isNotEmpty || r.isGeneric;
  // A constant can't name a type parameter, so a generic route's
  // `const ListEquality<dynamic>()` and the like compare items as dynamic.
  List<ResolvedType> equalityTypes(ParamConfig p) => r.isGeneric
      ? [
          for (final _ in p.type.typeArguments)
            const ResolvedType(name: 'dynamic'),
        ]
      : p.type.typeArguments;
  final pageInfoRefer = refer('PageInfo', kAutoRouteImport);
  return [
    Class(
      (b) => b
        ..docs.addAll([
          '/// generated route for \n/// [${_pageClassRefer(r)?.accept(emitter) ?? 'null'}]',
        ])
        ..name = r.getName(router.replaceInRouteName)
        ..types.addAll(r.typeParameters.map((t) => t.declaration))
        ..extend = TypeReference((typeReferenceBuilder) {
          typeReferenceBuilder
            ..symbol = 'PageRouteInfo'
            ..url = kAutoRouteImport
            ..types.add(hasArgs ? typedArgsClassRefer : refer('void'));
        })
        ..fields.addAll([
          Field(
            (fieldBuilder) => fieldBuilder
              ..modifier = .constant
              ..name = 'name'
              ..static = true
              ..type = kStringRefer
              ..assignment = _plainString(r.getName(router.replaceInRouteName))
                  .code,
          ),
          Field(
            (fieldBuilder) => fieldBuilder
              ..name = 'page'
              ..static = true
              ..type = pageInfoRefer
              ..assignment = pageInfoRefer
                  .newInstance(
                    [refer('name')],
                    {'builder': _buildMethod(r, router)},
                  )
                  .code,
          ),
        ])
        ..constructors.addAll([
          Constructor((constructorBuilder) {
            constructorBuilder
              // A type argument can't be part of a constant.
              ..constant = parameters.isEmpty && !r.isGeneric
              ..optionalParameters.addAll([
                ..._buildArgParams(
                  nonInheritedParameters,
                  emitter,
                  toThis: false,
                ),
                Parameter(
                  (parameterBuilder) => parameterBuilder
                    ..named = true
                    ..name = 'children'
                    ..type = listRefer(kPageRouteType, nullable: true),
                ),
              ])
              ..initializers.add(
                refer('super')
                    .call(
                      [
                        refer(r.getName(router.replaceInRouteName))
                            .property('name'),
                      ],
                      {
                        if (hasArgs)
                          'args': typedArgsClassRefer(
                            [],
                            Map.fromEntries(
                              nonInheritedParameters.map(
                                (p) => MapEntry(p.name, refer(p.getSafeName())),
                              ),
                            ),
                          ),
                        if (nonInheritedParameters.any((p) => p.isPathParam))
                          'rawPathParams': literalMap(
                            Map.fromEntries(
                              nonInheritedParameters
                                  .where((p) => p.isPathParam)
                                  .map(
                                    (p) => MapEntry(
                                      _plainString(p.paramName),
                                      _getUrlPartValue(p),
                                    ),
                                  ),
                            ),
                          ),
                        if (parameters.any((p) => p.isQueryParam))
                          'rawQueryParams': literalMap(
                            Map.fromEntries(
                              parameters
                                  .where((p) => p.isQueryParam)
                                  .map(
                                    (p) => MapEntry(
                                      _plainString(p.paramName),
                                      _getUrlPartValue(p),
                                    ),
                                  ),
                            ),
                          ),
                        if (fragmentParam != null)
                          'fragment': refer(fragmentParam.name),
                        'initialChildren': refer('children'),
                        if (!router.argsEquality)
                          'argsEquality': literalBool(false),
                      },
                    )
                    .code,
              );
          }),
        ]),
    ),
    if (hasArgs)
      Class(
        (b) => b
          ..name = argsClassRefer.symbol
          ..types.addAll(r.typeParameters.map((t) => t.declaration))
          ..fields.addAll([
            ...nonInheritedParameters.map(
              (param) => Field(
                (fieldBuilder) => fieldBuilder
                  ..modifier = .final$
                  ..name = param.name
                  ..type = param is FunctionParamConfig
                      ? param.funRefer
                      : param.type.refer,
              ),
            ),
          ])
          ..constructors.add(
            Constructor(
              (constructorBuilder) => constructorBuilder
                ..constant = true
                ..optionalParameters.addAll(
                  _buildArgParams(
                    nonInheritedParameters,
                    emitter,
                    useSafeName: false,
                  ),
                ),
            ),
          )
          ..methods.addAll([
            if (r.isGeneric) _buildPageMethod(r),
            Method(
              (methodBuilder) => methodBuilder
                ..name = 'toString'
                ..lambda = false
                ..annotations.add(refer('override'))
                ..returns = kStringRefer
                ..body = literalString(
                  '${_escapeDollar(r.getName(router.replaceInRouteName))}Args{${nonInheritedParameters.map((p) => '${_escapeDollar(p.name)}: ${_interpolation(p.name)}').join(', ')}}',
                ).returned.statement,
            ),
            if (router.argsEquality)
              Method(
                (methodBuilder) => methodBuilder
                  ..name = 'operator =='
                  ..lambda = false
                  ..annotations.add(refer('override'))
                  ..returns = refer('bool')
                  ..requiredParameters.add(
                    Parameter(
                      (parameterBuilder) => parameterBuilder
                        ..name = 'other'
                        ..type = refer('Object'),
                    ),
                  )
                  ..body = Block(
                    (blockBuilder) => blockBuilder
                      ..statements.addAll([
                        const Code('if (identical(this, other)) return true;'),
                        Code(
                          'if (other is! ${emitSource(typedArgsClassRefer, emitter)}) return false;',
                        ),
                        const Code('return '),
                        // Args with nothing to compare, such as a generic
                        // route's without params, are equal.
                        if (equatableParams.isEmpty) literalTrue.code,
                        ...[
                          for (final p in equatableParams)
                            if (p.type.isList)
                              _genericRef(
                                'ListEquality',
                                equalityTypes(p),
                                _kCollectionsImport,
                              ).constInstance([]).property('equals').call([
                                refer(p.name),
                                refer('other').property(p.name),
                              ]).code
                            else if (p.type.isSet)
                              _genericRef(
                                'SetEquality',
                                equalityTypes(p),
                                _kCollectionsImport,
                              ).constInstance([]).property('equals').call([
                                refer(p.name),
                                refer('other').property(p.name),
                              ]).code
                            else if (p.type.isMap)
                              _genericRef(
                                'MapEquality',
                                equalityTypes(p),
                                _kCollectionsImport,
                              ).constInstance([]).property('equals').call([
                                refer(p.name),
                                refer('other').property(p.name),
                              ]).code
                            else if (p.type.isIterable)
                              _genericRef(
                                'IterableEquality',
                                equalityTypes(p),
                                _kCollectionsImport,
                              ).constInstance([]).property('equals').call([
                                refer(p.name),
                                refer('other').property(p.name),
                              ]).code
                            else
                              Code('${p.name} == other.${p.name}'),
                        ].insertBetween(const Code(' && ')),
                        const Code(';'),
                      ]),
                  ),
              ),
            if (router.argsEquality)
              Method(
                (methodBuilder) => methodBuilder
                  ..name = 'hashCode'
                  ..type = .getter
                  ..annotations.add(refer('override'))
                  ..returns = refer('int')
                  ..lambda = true
                  ..body = Block(
                    (blockBuilder) => blockBuilder.statements.addAll(
                      [
                        if (equatableParams.isEmpty) literalNum(0).code,
                        for (final p in equatableParams)
                          if (p.type.isList)
                            _genericRef(
                              'ListEquality',
                              equalityTypes(p),
                              _kCollectionsImport,
                            ).constInstance([]).property('hash').call([
                              refer(p.name),
                            ]).code
                          else if (p.type.isSet)
                            _genericRef(
                              'SetEquality',
                              equalityTypes(p),
                              _kCollectionsImport,
                            ).constInstance([]).property('hash').call([
                              refer(p.name),
                            ]).code
                          else if (p.type.isMap)
                            _genericRef(
                              'MapEquality',
                              equalityTypes(p),
                              _kCollectionsImport,
                            ).constInstance([]).property('hash').call([
                              refer(p.name),
                            ]).code
                          else if (p.type.isIterable)
                            _genericRef(
                              'IterableEquality',
                              equalityTypes(p),
                              _kCollectionsImport,
                            ).constInstance([]).property('hash').call([
                              refer(p.name),
                            ]).code
                          else
                            Code('${p.name}.hashCode'),
                      ].insertBetween(const Code(' ^ ')),
                    ),
                  ),
              ),
          ]),
      ),
  ];
}

/// The `const` keyword opening a default value's code, not a name that
/// contains the text, such as `constTitle`.
final _constKeyword = RegExp(r'^const\b');

/// The default value of [p], written as [code] when given. A list or set
/// holding a declaration from another library, such as `const [Sort.asc]`,
/// gets that declaration's import prefix.
Expression _defaultValue(ParamConfig p, [String? code]) {
  code ??= p.defaultValueCode!;
  final symbol = p.defaultValueSymbol;
  final import = p.defaultValueImport;
  if (symbol == null || import == null) {
    final url = import ?? p.type.import;
    // The prefix goes on the class in `const UserId('me')`, not on `const`.
    if (url != null && _constKeyword.hasMatch(code)) {
      final value = code.replaceFirst(_constKeyword, '').trimLeft();
      return CodeExpression(
        Code.scope((allocate) => 'const ${allocate(refer(value, url))}'),
      );
    }
    return refer(code, url);
  }
  return CodeExpression(
    Code.scope(
      (allocate) => code!.replaceAll(
        RegExp('\\b${RegExp.escape(symbol)}\\b'),
        allocate(refer(symbol, import)),
      ),
    ),
  );
}

/// Builds a list of [Parameter]s from the given [parameters]
Iterable<Parameter> _buildArgParams(
  List<ParamConfig> parameters,
  DartEmitter emitter, {
  bool toThis = true,
  bool useSafeName = true,
}) {
  return parameters.map(
    (p) => Parameter((b) {
      Code? defaultCode;
      if (p.defaultValueCode != null) {
        if (_constKeyword.hasMatch(p.defaultValueCode!)) {
          if (p.defaultValueCode!.contains('[]')) {
            defaultCode = const Code('const []');
          } else if (p.defaultValueCode!.contains('{}')) {
            defaultCode = const Code('const {}');
          } else {
            defaultCode = Code(
              'const ${emitSource(_defaultValue(p, p.defaultValueCode!.replaceFirst(_constKeyword, '')), emitter)}',
            );
          }
        } else {
          defaultCode = _defaultValue(p).code;
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
    }),
  );
}

Expression _buildMethod(RouteConfig r, RouterConfig router) {
  final useConsConstructor =
      r.hasConstConstructor && !(r.deferredLoading ?? router.deferredLoading);
  var constructedPage = useConsConstructor
      ? r.pageType!.refer.constInstance([])
      : r.isGeneric
      ? refer('args').property('buildPage').call([], {
          for (final p in r.parameters.where(
            (parameter) => parameter.isInheritedPathParam,
          ))
            p.name: _getUrlPartAssignment(p),
        })
      : _getPageInstance(r, (p) => refer('args').property(p.name));

  if (r.hasWrappedRoute == true) {
    constructedPage = refer(
      'WrappedRoute',
      kAutoRouteImport,
    ).newInstance([], {'child': constructedPage});
  }

  if ((r.deferredLoading ?? router.deferredLoading) && r.pageType != null) {
    constructedPage = _getDeferredBuilder(r, constructedPage);
  }
  final inheritedParameters = r.parameters.where((p) => p.isInheritedPathParam);

  final nonInheritedParameters = r.parameters.where(
    (p) => !p.isInheritedPathParam,
  );
  return Method(
    (b) => b
      ..requiredParameters.add(
        Parameter((parameterBuilder) => parameterBuilder.name = 'data'),
      )
      ..body = Block(
        (blockBuilder) => blockBuilder.statements.addAll([
          if ((!r.hasUnparsableRequiredArgs) &&
                  r.parameters.any((p) => p.isPathParam) ||
              inheritedParameters.isNotEmpty)
            declareFinal('pathParams')
                .assign(refer('data').property('inheritedPathParams'))
                .statement,
          if (!r.hasUnparsableRequiredArgs &&
              r.parameters.any((p) => p.isQueryParam))
            declareFinal('queryParams')
                .assign(refer('data').property('queryParams'))
                .statement,
          if (nonInheritedParameters.isNotEmpty || r.isGeneric)
            declareFinal('args')
                .assign(
                  refer('data')
                      .property('argsAs')
                      .call(
                        [],
                        {
                          if (!r.hasUnparsableRequiredArgs)
                            'orElse': Method(
                              (methodBuilder) => methodBuilder
                                ..lambda = true
                                ..body = r.pathQueryParams.isEmpty
                                    ? refer(
                                        '${r.getName(router.replaceInRouteName)}Args',
                                      ).constInstance([]).code
                                    : refer('${r.getName(router.replaceInRouteName)}Args')
                                          .newInstance(
                                            [],
                                            Map.fromEntries(
                                              nonInheritedParameters
                                                  .where(
                                                    (p) =>
                                                        (p.isPathParam ||
                                                        p.isQueryParam ||
                                                        p.isUrlFragment),
                                                  )
                                                  .map(
                                                    (p) => MapEntry(
                                                      p.name,
                                                      _getUrlPartAssignment(p),
                                                    ),
                                                  ),
                                            ),
                                          )
                                          .code,
                            ).closure,
                        },
                        [refer('${r.getName(router.replaceInRouteName)}Args')],
                      ),
                )
                .statement,
          constructedPage.returned.statement,
        ]),
      ),
  ).closure;
}

Expression _getDeferredBuilder(RouteConfig r, Expression page) {
  return TypeReference(
    (b) => b
      ..symbol = 'DeferredWidget'
      ..url = kAutoRouteImport,
  ).newInstance([
    TypeReference(
      (b) => b
        ..symbol = 'loadLibrary'
        ..url = r.pageType!.refer.url,
    ),
    Method((b) => b..body = page.code).closure,
  ]);
}

/// The page built with each argument [arg] gives, and each inherited path
/// param read from the url.
Expression _getPageInstance(
  RouteConfig r,
  Expression Function(ParamConfig p) arg,
) {
  return r.pageType!.refer.newInstance(
    r.positionalParams.map(arg),
    Map.fromEntries(
      r.namedParams.map(
        (p) => MapEntry(
          p.name,
          p.isInheritedPathParam ? _getUrlPartAssignment(p) : arg(p),
        ),
      ),
    ),
  );
}

/// The page class without type arguments, as a doc comment names it.
Reference? _pageClassRefer(RouteConfig r) {
  final pageType = r.pageType;
  return pageType == null ? null : refer(pageType.name, pageType.import);
}

/// The args class method of a generic route that builds its page with the
/// args' type arguments, which the route's static page builder can't name.
/// An inherited path param, which isn't in the args, is passed to it.
Method _buildPageMethod(RouteConfig r) {
  final inherited = r.parameters.where((p) => p.isInheritedPathParam);
  return Method(
    (b) => b
      ..docs.add("/// Builds the page with this route's type arguments.")
      ..name = 'buildPage'
      ..returns = r.pageType!.refer
      ..optionalParameters.addAll(
        inherited.map(
          (p) => Parameter(
            (parameterBuilder) => parameterBuilder
              ..name = p.name
              ..named = true
              ..required = true
              ..type = p.type.refer,
          ),
        ),
      )
      ..lambda = true
      ..body = r.pageType!.refer
          .newInstance(
            r.positionalParams.map((p) => refer(p.name)),
            Map.fromEntries(
              r.namedParams.map((p) => MapEntry(p.name, refer(p.name))),
            ),
          )
          .code,
  );
}

Expression _getUrlPartAssignment(ParamConfig p) {
  if (!p.isPathParam && !p.isQueryParam)
    return refer('data').property('fragment');
  final params = refer(p.isPathParam ? 'pathParams' : 'queryParams');
  final key = _plainString(p.paramName);
  final defaultValue = p.defaultValueCode == null ? null : _defaultValue(p);
  final urlType = p.urlType;
  // A type a url can not give is read as it is, for a route that a required
  // argument keeps links out of.
  if (urlType == null) return params.property('get').call([key, ?defaultValue]);
  return urlType.read(params, key, p.type, defaultValue);
}

/// The value a url parameter puts in the url.
Expression _getUrlPartValue(ParamConfig p) =>
    p.urlType?.write(refer(p.name), p.type) ?? refer(p.name);
