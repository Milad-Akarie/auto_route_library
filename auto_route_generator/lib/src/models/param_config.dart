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
    required this._hasRequired,
    required this._isOptional,
    required this.isRequired,
    required this.isPathParam,
    required this.isQueryParam,
    required this.isUrlFragment,
    required this.isInheritedPathParam,
    this._alias,
    this.defaultValueCode,
    this.defaultValueImport,
    this.defaultValueSymbol,
    this._converter,
  });

  /// Deserializes the parameter from a json map
  factory fromJson(Map<String, dynamic> map) {
    if (map['isFunctionParam'] == true) {
      return FunctionParamConfig._fromJson(map);
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
      converter: map['converter'] == null
          ? null
          : ParamConverterRef._fromJson(map['converter'] as Map<String, dynamic>),
    );
  }

  /// the type of the parameter
  final ResolvedType type;

  /// the name of the parameter
  final String name;

  /// the alias of the parameter
  final String? _alias;

  /// whether the parameter is positional
  final bool isPositional;

  /// whether the parameter is optional
  final bool _isOptional;

  /// whether the parameter is required
  final bool _hasRequired;

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
  final ParamConverterRef? _converter;

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
    final converter = this._converter;
    return converter == null ? UrlParamType.of(type) : UrlParamType.converter(converter._name, converter._import);
  }

  /// Returns the alias if exists otherwise the name
  String get paramName => _alias ?? name;

  /// Serializes the parameter to a json map
  Map<String, dynamic> toJson() {
    return {
      'type': type.toJson(),
      'name': name,
      'alias': _alias,
      'isPositional': isPositional,
      'isOptional': _isOptional,
      'hasRequired': _hasRequired,
      'isRequired': isRequired,
      'isNamed': isNamed,
      'isPathParam': isPathParam,
      'isUrlFragment': isUrlFragment,
      'isInheritedPathParam': isInheritedPathParam,
      'isQueryParam': isQueryParam,
      'defaultValueCode': defaultValueCode,
      'defaultValueImport': defaultValueImport,
      'defaultValueSymbol': defaultValueSymbol,
      'converter': ?_converter?.toJson(),
    };
  }
}

/// holds constructor func-parameter info to be used
/// in generating route parameters.
class FunctionParamConfig extends ParamConfig {
  /// Default constructor
  const new({
    required this._returnType,
    required super.type,
    required super.name,
    required super.isPositional,
    required super.hasRequired,
    required super.isOptional,
    required super.isNamed,
    required super.isRequired,
    this._params = const [],
    super.alias,
    super.defaultValueCode,
    super.defaultValueImport,
  }) : super(isPathParam: false, isQueryParam: false, isInheritedPathParam: false, isUrlFragment: false);

  /// Deserializes the parameter from a json map
  factory _fromJson(Map<String, dynamic> map) {
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
  final ResolvedType _returnType;

  /// the list of parameters of the function
  final List<ParamConfig> _params;

  @override
  Map<String, dynamic> toJson() {
    return {
      // used for deserialization
      'isFunctionParam': true,
      'type': type.toJson(),
      'returnType': _returnType.toJson(),
      'name': name,
      'alias': _alias,
      'isPositional': isPositional,
      'isOptional': _isOptional,
      'hasRequired': _hasRequired,
      'isRequired': isRequired,
      'isNamed': isNamed,
      'isPathParam': isPathParam,
      'isQueryParam': isQueryParam,
      'defaultValueCode': defaultValueCode,
      'defaultValueImport': defaultValueImport,
      'params': _params.map((e) => e.toJson()).toList(),
    };
  }

  /// Returns the list of required parameters
  List<ParamConfig> get _requiredParams => _params.where((p) => p.isPositional && !p._isOptional).toList();

  /// Returns the list of optional parameters
  List<ParamConfig> get _optionalParams => _params.where((p) => p.isPositional && p._isOptional).toList();

  /// Returns the list of named parameters
  List<ParamConfig> get _namedOptionalParams =>
      _params.where((p) => p.isNamed && p._isOptional).toList(growable: false);

  /// Returns the list of named required parameters
  List<ParamConfig> get _namedRequiredParams =>
      _params.where((p) => p.isNamed && !p._isOptional).toList(growable: false);

  /// Returns A function reference of the function type
  cb.FunctionType get funRefer => cb.FunctionType(
    (b) => b
      ..returnType = _returnType.refer
      ..requiredParameters.addAll(_requiredParams.map((e) => e.type.refer))
      ..optionalParameters.addAll(_optionalParams.map((e) => e.type.refer))
      ..isNullable = type.isNullable
      ..namedParameters.addAll({}..addEntries(_namedOptionalParams.map((e) => MapEntry(e.name, e.type.refer))))
      ..namedRequiredParameters.addAll({}..addEntries(_namedRequiredParams.map((e) => MapEntry(e.name, e.type.refer)))),
  );
}

/// Holds information about a path parameter
class PathParamConfig {
  /// Default constructor
  const new _({required this._name, required this._isOptional});

  /// Deserializes the path parameter from a json map
  factory fromJson(Map<String, dynamic> map) {
    return PathParamConfig._(name: map['name'] as String, isOptional: map['isOptional'] as bool);
  }

  /// The name of the path parameter
  final String _name;

  /// Whether the path parameter is optional
  final bool _isOptional;

  /// Serializes the path parameter to a json map
  Map<String, dynamic> toJson() {
    return {'name': _name, 'isOptional': _isOptional};
  }
}

/// The top-level constant a `@PathParam` or `@QueryParam` names as its
/// `ParamConverter`, which the generated code reads and writes the param
/// with.
class ParamConverterRef {
  /// Default constructor
  const new({required this._name, this._import});

  /// Deserializes the reference from a json map
  factory _fromJson(Map<String, dynamic> map) {
    return ParamConverterRef(name: map['name'] as String, import: map['import'] as String?);
  }

  /// The name of the constant, such as `userIdConverter`.
  final String _name;

  /// The import of the library that declares the constant.
  final String? _import;

  /// Serializes the reference to a json map
  Map<String, dynamic> toJson() => {'name': _name, 'import': _import};
}
