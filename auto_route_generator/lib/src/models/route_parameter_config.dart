import 'package:code_builder/code_builder.dart' as _code;

import 'importable_type.dart';

const reservedVarNames = ['children'];

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

class ParamConfig {
  final ResolvedType type;
  final String name;
  final String? alias;
  final bool isPositional;
  final bool isOptional;
  final bool hasRequired;
  final bool isRequired;
  final bool isNamed;
  final bool isPathParam;
  final bool isInheritedPathParam;
  final bool isQueryParam;
  final String? defaultValueCode;

  ParamConfig({
    required this.type,
    required this.name,
    required this.isNamed,
    required this.isPositional,
    required this.hasRequired,
    required this.isOptional,
    required this.isRequired,
    required this.isPathParam,
    required this.isQueryParam,
    required this.isInheritedPathParam,
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

  String get getterMethodName {
    switch (type.name) {
      case 'String':
        return type.isNullable ? 'optString' : 'getString';
      case 'int':
        return type.isNullable ? 'optInt' : 'getInt';
      case 'double':
        return type.isNullable ? 'optDouble' : 'getDouble';
      case 'num':
        return type.isNullable ? 'optNum' : 'getNum';
      case 'bool':
        return type.isNullable ? 'optBool' : 'getBool';
      default:
        return 'get';
    }
  }

  String get paramName => alias ?? name;

  Map<String, dynamic> toJson() {
    return {
      'type': this.type.toJson(),
      'name': this.name,
      'alias': this.alias,
      'isPositional': this.isPositional,
      'isOptional': this.isOptional,
      'hasRequired': this.hasRequired,
      'isRequired': this.isRequired,
      'isNamed': this.isNamed,
      'isPathParam': this.isPathParam,
      'isInheritedPathParam': this.isInheritedPathParam,
      'isQueryParam': this.isQueryParam,
      'defaultValueCode': this.defaultValueCode,
    };
  }

  factory ParamConfig.fromJson(Map<String, dynamic> map) {
    if (map['isFunctionParam'] == true) {
      return FunctionParamConfig.fromJson(map);
    }

    return ParamConfig(
      type: ResolvedType.fromJson(map['type']),
      name: map['name'] as String,
      alias: map['alias'] as String?,
      isPositional: map['isPositional'] as bool,
      isOptional: map['isOptional'] as bool,
      hasRequired: map['hasRequired'] as bool,
      isRequired: map['isRequired'] as bool,
      isNamed: map['isNamed'] as bool,
      isPathParam: map['isPathParam'] as bool,
      isInheritedPathParam: map['isInheritedPathParam'] as bool,
      isQueryParam: map['isQueryParam'] as bool,
      defaultValueCode: map['defaultValueCode'] as String?,
    );
  }
}

class FunctionParamConfig extends ParamConfig {
  final ResolvedType returnType;
  final List<ParamConfig> params;

  FunctionParamConfig({
    required this.returnType,
    this.params = const [],
    required ResolvedType type,
    required String name,
    String? alias,
    required bool isPositional,
    required bool hasRequired,
    required bool isOptional,
    required bool isNamed,
    required bool isRequired,
    String? defaultValueCode,
  }) : super(
          type: type,
          name: name,
          alias: alias,
          isPathParam: false,
          isQueryParam: false,
          isInheritedPathParam: false,
          isNamed: isNamed,
          defaultValueCode: defaultValueCode,
          isPositional: isPositional,
          hasRequired: hasRequired,
          isRequired: isRequired,
          isOptional: isOptional,
        );

  Map<String, dynamic> toJson() {
    return {
      // used for deserialization
      'isFunctionParam': true,
      'type': this.type.toJson(),
      'returnType': this.returnType.toJson(),
      'name': this.name,
      'alias': this.alias,
      'isPositional': this.isPositional,
      'isOptional': this.isOptional,
      'hasRequired': this.hasRequired,
      'isRequired': this.isRequired,
      'isNamed': this.isNamed,
      'isPathParam': this.isPathParam,
      'isQueryParam': this.isQueryParam,
      'defaultValueCode': this.defaultValueCode,
      'params': this.params.map((e) => e.toJson()).toList(),
    };
  }

  factory FunctionParamConfig.fromJson(Map<String, dynamic> map) {
    final params = <ParamConfig>[];
    if (map['params'] != null) {
      for (final pJson in map['params']) {
        params.add(ParamConfig.fromJson(pJson));
      }
    }
    return FunctionParamConfig(
      type: ResolvedType.fromJson(map['type']),
      returnType: ResolvedType.fromJson(map['returnType']),
      name: map['name'] as String,
      params: params,
      alias: map['alias'] as String?,
      isPositional: map['isPositional'] as bool,
      isOptional: map['isOptional'] as bool,
      hasRequired: map['hasRequired'] as bool,
      isRequired: map['isRequired'] as bool,
      isNamed: map['isNamed'] as bool,
      defaultValueCode: map['defaultValueCode'] as String?,
    );
  }

  List<ParamConfig> get requiredParams =>
      params.where((p) => p.isPositional && !p.isOptional).toList();

  List<ParamConfig> get optionalParams =>
      params.where((p) => p.isPositional && p.isOptional).toList();

  List<ParamConfig> get namedParams =>
      params.where((p) => p.isNamed).toList(growable: false);

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
}

class PathParamConfig {
  final String name;
  final bool isOptional;

  const PathParamConfig({required this.name, required this.isOptional});

  Map<String, dynamic> toJson() {
    return {
      'name': this.name,
      'isOptional': this.isOptional,
    };
  }

  factory PathParamConfig.fromJson(Map<String, dynamic> map) {
    return PathParamConfig(
      name: map['name'] as String,
      isOptional: map['isOptional'] as bool,
    );
  }
}
