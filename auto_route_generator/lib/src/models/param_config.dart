import 'package:auto_route_generator/src/models/resolved_type.dart';
import 'package:auto_route_generator/src/models/url_param_type.dart';
import 'package:code_builder/code_builder.dart' as cb;

const _kReservedVarNames = ['children'];

/// holds constructor parameter info to be used
/// in generating route parameters.
class ParamConfig {
  /// Default constructor
  const new({
    required this.type,
    required this.name,
    required this.isNamed,
    required this.isPositional,
    required this.hasRequired,
    required this.isOptional,
    required this.isRequired,
    required this.isPathParam,
    required this.isQueryParam,
    required this.isUrlFragment,
    required this.isInheritedPathParam,
    this.alias,
    this.defaultValueCode,
    this.defaultValueImport,
    this.defaultValueSymbol,
    this.converter,
  });

  /// Deserializes the parameter from a json map
  factory fromJson(Map<String, dynamic> map) {
    if (map['isFunctionParam'] == true) {
      return FunctionParamConfig.fromJson(map);
    }

    return ParamConfig(
      type: ResolvedType.fromJson(map['type'] as Map<String, dynamic>),
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
      isUrlFragment: map['isUrlFragment'] as bool,
      defaultValueCode: map['defaultValueCode'] as String?,
      defaultValueImport: map['defaultValueImport'] as String?,
      defaultValueSymbol: map['defaultValueSymbol'] as String?,
      converter: map['converter'] == null ? null : ParamConverterRef.fromJson(map['converter'] as Map<String, dynamic>),
    );
  }

  /// the type of the parameter
  final ResolvedType type;

  /// the name of the parameter
  final String name;

  /// the alias of the parameter
  final String? alias;

  /// whether the parameter is positional
  final bool isPositional;

  /// whether the parameter is optional
  final bool isOptional;

  /// whether the parameter is required
  final bool hasRequired;

  /// whether the parameter is required
  final bool isRequired;

  /// whether the parameter is named
  final bool isNamed;

  /// whether the parameter is a path param
  final bool isPathParam;

  /// whether the parameter is a url fragment
  final bool isUrlFragment;

  /// whether the parameter is an inherited path param
  final bool isInheritedPathParam;

  /// whether the parameter is a query param
  final bool isQueryParam;

  /// the default value code of the parameter
  final String? defaultValueCode;

  /// the import of the declaration the default value names, such as a
  /// function or a constant from another library
  final String? defaultValueImport;

  /// The name of the declaration [defaultValueImport] imports, when the
  /// default value is a list or set holding it, such as `Sort` in
  /// `const [Sort.asc]`; `null` when the whole value is that declaration.
  final String? defaultValueSymbol;

  /// The `ParamConverter` the param's `@PathParam` or `@QueryParam` names,
  /// or `null` when it names none.
  final ParamConverterRef? converter;

  /// If the parameter name conflicts with a reserved name
  /// add a zero to the end of the name
  ///
  /// e.g. children -> children0
  ///
  /// otherwise return the name as is
  String getSafeName() {
    if (_kReservedVarNames.contains(name)) {
      return '${name}0';
    }
    return name;
  }

  /// How the generated code reads this param from the url and writes it
  /// back, or `null` when a url can not give its type.
  UrlParamType? get urlType {
    final converter = this.converter;
    return converter == null ? UrlParamType.of(type) : UrlParamType.converter(converter.name, converter.import);
  }

  /// Returns the alias if exists otherwise the name
  String get paramName => alias ?? name;

  /// Serializes the parameter to a json map
  Map<String, dynamic> toJson() {
    return {
      'type': type.toJson(),
      'name': name,
      'alias': alias,
      'isPositional': isPositional,
      'isOptional': isOptional,
      'hasRequired': hasRequired,
      'isRequired': isRequired,
      'isNamed': isNamed,
      'isPathParam': isPathParam,
      'isUrlFragment': isUrlFragment,
      'isInheritedPathParam': isInheritedPathParam,
      'isQueryParam': isQueryParam,
      'defaultValueCode': defaultValueCode,
      'defaultValueImport': defaultValueImport,
      'defaultValueSymbol': defaultValueSymbol,
      'converter': ?converter?.toJson(),
    };
  }
}

/// holds constructor func-parameter info to be used
/// in generating route parameters.
class FunctionParamConfig extends ParamConfig {
  /// Default constructor
  const new({
    required this.returnType,
    this.params = const [],
    required super.type,
    required super.name,
    super.alias,
    required super.isPositional,
    required super.hasRequired,
    required super.isOptional,
    required super.isNamed,
    required super.isRequired,
    super.defaultValueCode,
    super.defaultValueImport,
  }) : super(isPathParam: false, isQueryParam: false, isInheritedPathParam: false, isUrlFragment: false);

  /// Deserializes the parameter from a json map
  factory fromJson(Map<String, dynamic> map) {
    final params = <ParamConfig>[];
    final paramsJson = (map['params'] as List<Object?>?)?.cast<Map<String, dynamic>>();
    if (paramsJson != null) {
      for (final pJson in paramsJson) {
        params.add(ParamConfig.fromJson(pJson));
      }
    }
    return FunctionParamConfig(
      type: ResolvedType.fromJson(map['type'] as Map<String, dynamic>),
      returnType: ResolvedType.fromJson(map['returnType'] as Map<String, dynamic>),
      name: map['name'] as String,
      params: params,
      alias: map['alias'] as String?,
      isPositional: map['isPositional'] as bool,
      isOptional: map['isOptional'] as bool,
      hasRequired: map['hasRequired'] as bool,
      isRequired: map['isRequired'] as bool,
      isNamed: map['isNamed'] as bool,
      defaultValueCode: map['defaultValueCode'] as String?,
      defaultValueImport: map['defaultValueImport'] as String?,
    );
  }

  /// the return type of the function
  final ResolvedType returnType;

  /// the list of parameters of the function
  final List<ParamConfig> params;

  @override
  Map<String, dynamic> toJson() {
    return {
      // used for deserialization
      'isFunctionParam': true,
      'type': type.toJson(),
      'returnType': returnType.toJson(),
      'name': name,
      'alias': alias,
      'isPositional': isPositional,
      'isOptional': isOptional,
      'hasRequired': hasRequired,
      'isRequired': isRequired,
      'isNamed': isNamed,
      'isPathParam': isPathParam,
      'isQueryParam': isQueryParam,
      'defaultValueCode': defaultValueCode,
      'defaultValueImport': defaultValueImport,
      'params': params.map((e) => e.toJson()).toList(),
    };
  }

  /// Returns the list of required parameters
  List<ParamConfig> get requiredParams => params.where((p) => p.isPositional && !p.isOptional).toList();

  /// Returns the list of optional parameters
  List<ParamConfig> get optionalParams => params.where((p) => p.isPositional && p.isOptional).toList();

  /// Returns the list of named parameters
  List<ParamConfig> get namedOptionalParams => params.where((p) => p.isNamed && p.isOptional).toList(growable: false);

  /// Returns the list of named required parameters
  List<ParamConfig> get namedRequiredParams => params.where((p) => p.isNamed && !p.isOptional).toList(growable: false);

  /// Returns A function reference of the function type
  cb.FunctionType get funRefer => cb.FunctionType(
    (b) => b
      ..returnType = returnType.refer
      ..requiredParameters.addAll(requiredParams.map((e) => e.type.refer))
      ..optionalParameters.addAll(optionalParams.map((e) => e.type.refer))
      ..isNullable = type.isNullable
      ..namedParameters.addAll({}..addEntries(namedOptionalParams.map((e) => MapEntry(e.name, e.type.refer))))
      ..namedRequiredParameters.addAll({}..addEntries(namedRequiredParams.map((e) => MapEntry(e.name, e.type.refer)))),
  );
}

/// Holds information about a path parameter
class PathParamConfig {
  /// Default constructor
  const new({required this.name, required this.isOptional});

  /// Deserializes the path parameter from a json map
  factory fromJson(Map<String, dynamic> map) {
    return PathParamConfig(name: map['name'] as String, isOptional: map['isOptional'] as bool);
  }

  /// The name of the path parameter
  final String name;

  /// Whether the path parameter is optional
  final bool isOptional;

  /// Serializes the path parameter to a json map
  Map<String, dynamic> toJson() {
    return {'name': name, 'isOptional': isOptional};
  }
}

/// The top-level constant a `@PathParam` or `@QueryParam` names as its
/// `ParamConverter`, which the generated code reads and writes the param
/// with.
class ParamConverterRef {
  /// Default constructor
  const new({required this.name, this.import});

  /// Deserializes the reference from a json map
  factory fromJson(Map<String, dynamic> map) {
    return ParamConverterRef(name: map['name'] as String, import: map['import'] as String?);
  }

  /// The name of the constant, such as `userIdConverter`.
  final String name;

  /// The import of the library that declares the constant.
  final String? import;

  /// Serializes the reference to a json map
  Map<String, dynamic> toJson() => {'name': name, 'import': import};
}
