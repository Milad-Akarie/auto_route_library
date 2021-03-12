import 'package:analyzer/dart/element/element.dart' show ParameterElement;
import 'package:code_builder/code_builder.dart' as _code;

import 'importable_type.dart';

const reservedVarNames = ['name', 'children'];

const validPathParamTypes = ['String', 'int', 'double', 'num', 'bool', 'dynamic'];

/// holds constructor parameter info to be used
/// in generating route parameters.

class ParamConfig {
  final ImportableType type;
  final String name;
  final String? alias;
  final bool isPositional;
  final bool isOptional;
  final bool hasRequired;
  final bool isRequired;
  final bool isNamed;
  final bool isPathParam;
  final bool isQueryParam;
  final String? defaultValueCode;
  final ParameterElement element;

  ParamConfig({
    required this.type,
    required this.name,
    required this.element,
    required this.isNamed,
    required this.isPositional,
    required this.hasRequired,
    required this.isOptional,
    required this.isRequired,
    required this.isPathParam,
    required this.isQueryParam,
    this.alias,
    this.defaultValueCode,
  });

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
        return type.isNullable ? 'getStringOrNull' : 'getString';
      case 'int':
        return type.isNullable ? 'getIntOrNull' : 'getInt';
      case 'double':
        return type.isNullable ? 'getDoubleOrNull' : 'getDouble';
      case 'num':
        return type.isNullable ? 'getNumOrNull' : 'getNum';
      case 'bool':
        return type.isNullable ? 'getBoolOrNull' : 'getBool';
      default:
        return 'get';
    }
  }

  String get paramName => alias ?? name;

  _code.Code? get defaultCode => defaultValueCode == null ? null : _code.Code(defaultValueCode);

  Set<String> get imports => type.imports;
}

class FunctionParamConfig extends ParamConfig {
  final ImportableType returnType;
  final List<ParamConfig> params;

  FunctionParamConfig({
    required this.returnType,
    this.params = const [],
    required ImportableType type,
    required String name,
    String? alias,
    required bool isPositional,
    required bool hasRequired,
    required bool isOptional,
    required bool isNamed,
    required ParameterElement element,
    required bool isRequired,
    String? defaultValueCode,
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

  List<ParamConfig> get requiredParams => params.where((p) => p.isPositional && !p.isOptional).toList();

  List<ParamConfig> get optionalParams => params.where((p) => p.isPositional && p.isOptional).toList();

  List<ParamConfig> get namedParams => params.where((p) => p.isNamed).toList(growable: false);

  _code.FunctionType get funRefer => _code.FunctionType((b) => b
    ..returnType = returnType.refer
    ..requiredParameters.addAll(requiredParams.map((e) => e.type.refer))
    ..optionalParameters.addAll(optionalParams.map((e) => e.type.refer))
    ..isNullable = type.isNullable
    ..namedParameters.addAll(
      {}..addEntries(namedParams.map(
          (e) => MapEntry(e.name, e.type.refer),
        )),
    ));

  @override
  Set<String> get imports {
    var allImports = <String>{};
    allImports.addAll(returnType.imports);
    allImports.addAll(type.imports);
    params.forEach((param) {
      allImports.addAll(param.imports);
    });
    return {...returnType.imports, ...type.imports, ...params.map((e) => e.imports).reduce((acc, a) => acc..addAll(a))};
  }
}

class PathParamConfig {
  final String name;
  final bool isOptional;

  const PathParamConfig({required this.name, required this.isOptional});
}
