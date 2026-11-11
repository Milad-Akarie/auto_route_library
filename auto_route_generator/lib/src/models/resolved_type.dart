import 'package:code_builder/code_builder.dart'
    show FunctionType, RecordType, Reference, TypeReference;
import 'package:meta/meta.dart';

/// A class that represents a resolved type.
///
/// holds the type name, import, type arguments and nullability
@immutable
class ResolvedType {
  /// Default constructor
  const new({
    required this.name,
    this.import,
    this.typeArguments = const [],
    this.isNullable = false,
    this._nameInRecord,
    this.isEnum = false,
  }) : _isRecordType = false,
       _functionParts = null;

  const new _({
    required this.name,
    required this._isRecordType,
    required this.import,
    required this.typeArguments,
    required this.isNullable,
    required this._nameInRecord,
    required this._functionParts,
    required this.isEnum,
  });

  /// Constructor for a record types
  const new record({
    required this.name,
    required this.import,
    required this.typeArguments,
    required this.isNullable,
    this._nameInRecord,
  }) : _isRecordType = true,
       _functionParts = null,
       isEnum = false;

  /// Constructor for a function type, such as `void Function(String url)`,
  /// when it is a type argument or a record field
  const new function({
    required FunctionTypeParts parts,
    required this.isNullable,
    required this._nameInRecord,
  }) : name = 'Function',
       import = null,
       typeArguments = const [],
       _isRecordType = false,
       _functionParts = parts,
       isEnum = false;

  /// deserializes the type from json
  factory fromJson(Map<String, dynamic> map) {
    final typedArgs = <ResolvedType>[];
    final typeArguments = (map['typeArguments'] as List<Object?>?)
        ?.cast<Map<String, dynamic>>();
    if (typeArguments != null) {
      for (final arg in typeArguments) {
        typedArgs.add(ResolvedType.fromJson(arg));
      }
    }
    return ResolvedType._(
      import: map['import'] as String?,
      name: map['name'] as String,
      isNullable: map['isNullable'] as bool,
      isRecordType: map['isRecordType'] as bool,
      nameInRecord: map['nameInRecord'] as String?,
      typeArguments: typedArgs,
      functionParts: map['functionParts'] == null
          ? null
          : FunctionTypeParts._fromJson(
              map['functionParts'] as Map<String, dynamic>,
            ),
      isEnum: map['isEnum'] == true,
    );
  }

  /// the import path of the type
  final String? import;

  /// the type name
  final String name;

  /// whether the type is nullable
  final bool isNullable;

  /// the type arguments
  final List<ResolvedType> typeArguments;
  final bool _isRecordType;

  /// the name of the field in the record
  final String? _nameInRecord;

  /// the parts of a function type, `null` for any other type
  final FunctionTypeParts? _functionParts;

  /// whether the type is an enum
  final bool isEnum;

  /// the unique identity of the type
  String get _identity => '${import ?? ''}#$name';

  /// whether the type is for a named record field
  bool get _isNamedRecordField => _nameInRecord != null;

  /// Creates a [TypeReference] from the type
  Reference get refer {
    final functionParts = _functionParts;
    if (functionParts != null) {
      return FunctionType(
        (b) => b
          ..isNullable = isNullable
          ..returnType = functionParts._returnType.refer
          ..requiredParameters.addAll(
            functionParts._requiredParameters.map((e) => e.refer),
          )
          ..optionalParameters.addAll(
            functionParts._optionalParameters.map((e) => e.refer),
          )
          ..namedParameters.addAll({
            for (final entry in functionParts._namedParameters.entries)
              entry.key: entry.value.refer,
          })
          ..namedRequiredParameters.addAll({
            for (final entry in functionParts._namedRequiredParameters.entries)
              entry.key: entry.value.refer,
          }),
      );
    }
    if (_isRecordType) {
      return RecordType(
        (b) => b
          ..url = import
          ..isNullable = isNullable
          ..positionalFieldTypes.addAll(
            typeArguments
                .where((e) => !e._isNamedRecordField)
                .map((e) => e.refer),
          )
          ..namedFieldTypes.addAll({
            for (final entry in typeArguments.where(
              (e) => e._isNamedRecordField,
            ))
              entry._nameInRecord!: entry.refer,
          }),
      );
    }
    return TypeReference(
      (b) => b
        ..symbol = name
        ..url = import
        ..isNullable = isNullable
        ..types.addAll(typeArguments.map((e) => e.refer)),
    );
  }

  @override
  String toString() {
    return name;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResolvedType &&
          runtimeType == other.runtimeType &&
          _identity == other._identity;

  @override
  int get hashCode => import.hashCode ^ name.hashCode;

  /// serializes the type to json
  Map<String, dynamic> toJson() {
    return {
      'import': import,
      'name': name,
      'isNullable': isNullable,
      'isRecordType': _isRecordType,
      'nameInRecord': ?_nameInRecord,
      if (typeArguments.isNotEmpty)
        'typeArguments': typeArguments.map((e) => e.toJson()).toList(),
      'functionParts': ?_functionParts?.toJson(),
      if (isEnum) 'isEnum': true,
    };
  }

  /// whether the type is a list
  bool get isList => name == 'List';

  /// whether the type is a map
  bool get isMap => name == 'Map';

  /// whether the type is a set
  bool get isSet => name == 'Set';

  /// whether the type is a iterable
  bool get isIterable => name == 'Iterable';
}

/// The return type and parameter types of a function type.
class FunctionTypeParts {
  /// Default constructor
  const new({
    required this._returnType,
    required this._requiredParameters,
    required this._optionalParameters,
    required this._namedParameters,
    required this._namedRequiredParameters,
  });

  /// deserializes the parts from json
  factory _fromJson(Map<String, dynamic> map) {
    List<ResolvedType> list(String key) => [
      for (final e in (map[key] as List<Object?>).cast<Map<String, dynamic>>())
        ResolvedType.fromJson(e),
    ];
    Map<String, ResolvedType> named(String key) => {
      for (final e in (map[key] as Map<String, dynamic>).entries)
        e.key: ResolvedType.fromJson(e.value as Map<String, dynamic>),
    };
    return FunctionTypeParts(
      returnType: ResolvedType.fromJson(
        map['returnType'] as Map<String, dynamic>,
      ),
      requiredParameters: list('requiredParameters'),
      optionalParameters: list('optionalParameters'),
      namedParameters: named('namedParameters'),
      namedRequiredParameters: named('namedRequiredParameters'),
    );
  }

  /// the return type
  final ResolvedType _returnType;

  /// the types of the required positional parameters
  final List<ResolvedType> _requiredParameters;

  /// the types of the optional positional parameters
  final List<ResolvedType> _optionalParameters;

  /// the types of the optional named parameters, by name
  final Map<String, ResolvedType> _namedParameters;

  /// the types of the required named parameters, by name
  final Map<String, ResolvedType> _namedRequiredParameters;

  /// serializes the parts to json
  Map<String, dynamic> toJson() {
    return {
      'returnType': _returnType.toJson(),
      'requiredParameters': _requiredParameters.map((e) => e.toJson()).toList(),
      'optionalParameters': _optionalParameters.map((e) => e.toJson()).toList(),
      'namedParameters': _namedParameters.map(
        (k, v) => MapEntry(k, v.toJson()),
      ),
      'namedRequiredParameters': _namedRequiredParameters.map(
        (k, v) => MapEntry(k, v.toJson()),
      ),
    };
  }
}
