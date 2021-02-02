import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:auto_route/annotations.dart';
import 'package:auto_route_generator/import_resolver.dart';
import 'package:code_builder/code_builder.dart' as _code;
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';

final pathParamChecker = TypeChecker.fromRuntime(PathParam);
final queryParamChecker = TypeChecker.fromRuntime(QueryParam);

const reservedVarNames = ['name', 'children'];

const validPathParamTypes = [
  'String',
  'int',
  'double',
  'num',
  'bool',
  'dynamic'
];

/// holds constructor parameter info to be used
/// in generating route parameters.
///

class ParamConfig {
  final ImportableType type;
  final String name;
  final String alias;
  final bool isPositional;
  final bool isOptional;
  final bool hasRequired;
  final bool isRequired;
  final bool isNamed;
  final bool isPathParam;
  final bool isQueryParam;
  final String defaultValueCode;
  final ParameterElement element;

  ParamConfig(
      {@required this.type,
      @required this.name,
      this.alias,
      this.element,
      @required this.isNamed,
      @required this.isPositional,
      @required this.hasRequired,
      @required this.isOptional,
      @required this.isRequired,
      @required this.isPathParam,
      @required this.isQueryParam,
      this.defaultValueCode});

  String getSafeName() {
    if (reservedVarNames.contains(name)) {
      return name + "0";
    } else {
      return name;
    }
  }

  String get getterName {
    switch (type.name) {
      case 'String':
        return 'stringValue';
      case 'int':
        return 'intValue';
      case 'double':
        return 'doubleValue';
      case 'num':
        return 'numValue';
      case 'bool':
        return 'boolValue';
      default:
        return 'value';
    }
  }

  String get getterMethodName {
    switch (type.name) {
      case 'String':
        return 'getString';
      case 'int':
        return 'getInt';
      case 'double':
        return 'getDouble';
      case 'num':
        return 'getNum';
      case 'bool':
        return 'getBool';
      default:
        return 'get';
    }
  }

  String get paramName => alias ?? name;

  _code.Code get defaultCode =>
      defaultValueCode == null ? null : _code.Code(defaultValueCode);

  Set<String> get imports => type.imports;
}

class RouteParameterResolver {
  final TypeResolver _typeResolver;

  RouteParameterResolver(this._typeResolver);

  ParamConfig resolve(ParameterElement parameterElement) {
    final paramType = parameterElement.type;
    if (paramType is FunctionType) {
      return _resolveFunctionType(parameterElement);
    }

    var isPathParam = pathParamChecker.hasAnnotationOfExact(parameterElement);
    var paramAlias;
    if (isPathParam) {
      paramAlias = pathParamChecker
          .firstAnnotationOf(parameterElement)
          .getField('name')
          ?.toStringValue();
    }
    var isQuery = queryParamChecker.hasAnnotationOfExact(parameterElement);
    if (isQuery) {
      paramAlias = queryParamChecker
          .firstAnnotationOf(parameterElement)
          .getField('name')
          ?.toStringValue();
    }

    return ParamConfig(
      type: _typeResolver.resolveType(paramType),
      element: parameterElement,
      name: parameterElement.name.replaceFirst("_", ''),
      alias: paramAlias,
      isPositional: parameterElement.isPositional,
      hasRequired: parameterElement.hasRequired,
      isRequired: parameterElement.isRequiredNamed,
      isOptional: parameterElement.isOptional,
      isNamed: parameterElement.isNamed,
      isPathParam: isPathParam,
      isQueryParam: isQuery,
      defaultValueCode: parameterElement.defaultValueCode,
    );
  }

  ParamConfig _resolveFunctionType(ParameterElement paramElement) {
    var type = paramElement.type as FunctionType;
    return FunctionParamConfig(
        returnType: _typeResolver.resolveType(type.returnType),
        type: _typeResolver.resolveType(type),
        params: type.parameters.map(resolve).toList(),
        element: paramElement,
        name: paramElement.name,
        isRequired: paramElement.isRequiredNamed,
        isPositional: paramElement.isPositional,
        hasRequired: paramElement.hasRequired,
        isOptional: paramElement.isOptional,
        isNamed: paramElement.isNamed);
  }

  static List<PathParamConfig> extractPathParams(String path) {
    return RegExp(r':([^/]+)').allMatches(path).map((m) {
      var paramName = m.group(1);
      var isOptional = false;
      if (paramName.endsWith('?')) {
        isOptional = true;
        paramName = paramName.substring(0, paramName.length - 1);
      }
      return PathParamConfig(
        name: paramName,
        isOptional: isOptional,
      );
    }).toList();
  }
}

class FunctionParamConfig extends ParamConfig {
  final ImportableType returnType;
  final List<ParamConfig> params;

  FunctionParamConfig({
    @required this.returnType,
    this.params,
    @required ImportableType type,
    @required String name,
    String alias,
    @required bool isPositional,
    @required bool hasRequired,
    @required bool isOptional,
    @required bool isNamed,
    ParameterElement element,
    @required bool isRequired,
    String defaultValueCode,
  }) : super(
          type: type,
          name: name,
          alias: alias,
          isPathParam: false,
          isQueryParam: false,
          isNamed: isNamed,
          element: element,
          isPositional: isPositional,
          hasRequired: hasRequired,
          isRequired: isRequired,
          isOptional: isOptional,
        );

  List<ParamConfig> get requiredParams => params
      .where((p) => p.isPositional && !p.isOptional)
      .toList(growable: false);

  List<ParamConfig> get optionalParams => params
      .where((p) => p.isPositional && p.isOptional)
      .toList(growable: false);

  List<ParamConfig> get namedParams =>
      params.where((p) => p.isNamed).toList(growable: false);

  _code.FunctionType get funRefer => _code.FunctionType((b) => b
    ..returnType = returnType.refer
    ..requiredParameters.addAll(requiredParams.map((e) => e.type.refer))
    ..optionalParameters.addAll(optionalParams.map((e) => e.type.refer))
    ..namedParameters.addAll(
      {}..addEntries(namedParams.map(
          (e) => MapEntry(e.name, e.type.refer),
        )),
    ));

  @override
  Set<String> get imports => {
        ...returnType.imports,
        ...type.imports,
        ...params.map((e) => e.imports).reduce((acc, a) => acc..addAll(a))
      };
}

class PathParamConfig {
  final String name;
  final bool isOptional;

  const PathParamConfig({this.name, this.isOptional});
}
