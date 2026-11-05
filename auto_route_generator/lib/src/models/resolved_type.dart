import 'package:code_builder/code_builder.dart' show FunctionType, RecordType, Reference, TypeReference;
import 'package:meta/meta.dart';

/// A class that represents a resolved type.
///
/// holds the type name, import, type arguments and nullability
@immutable
class ResolvedType {
  /// Default constructor
  const ResolvedType({
    required this.name,
    this.import,
    this.typeArguments = const [],
    this.isNullable = false,
    this.nameInRecord,
    this.isEnum = false,
  }) : _isRecordType = false,
       functionParts = null;

  const ResolvedType._({
    required this.name,
    this.import,
    this.typeArguments = const [],
    this.isNullable = false,
    required this._isRecordType,
    this.nameInRecord,
    this.functionParts,
    this.isEnum = false,
  });

  /// Constructor for a record types
  const ResolvedType.record({
    required this.name,
    this.import,
    this.typeArguments = const [],
    this.isNullable = false,
    this.nameInRecord,
  }) : _isRecordType = true,
       functionParts = null,
       isEnum = false;

  /// Constructor for a function type, such as `void Function(String url)`,
  /// when it is a type argument or a record field
  const ResolvedType.function({required FunctionTypeParts parts, this.isNullable = false, this.nameInRecord})
    : name = 'Function',
      import = null,
      typeArguments = const [],
      _isRecordType = false,
      functionParts = parts,
      isEnum = false;

  /// deserializes the type from json
  factory ResolvedType.fromJson(Map<String, dynamic> map) {
    final typedArgs = <ResolvedType>[];
    final typeArguments = map['typeArguments'] as List<Object?>?;
    if (typeArguments != null) {
      for (final arg in typeArguments) {
        typedArgs.add(ResolvedType.fromJson(arg as Map<String, dynamic>));
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
          : FunctionTypeParts.fromJson(map['functionParts'] as Map<String, dynamic>),
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
  final String? nameInRecord;

  /// the parts of a function type, `null` for any other type
  final FunctionTypeParts? functionParts;

  /// whether the type is an enum
  final bool isEnum;

  /// the unique identity of the type
  String get identity => '${import ?? ''}#$name';

  /// whether the type is for a named record field
  bool get isNamedRecordField => nameInRecord != null;

  /// Creates a [TypeReference] from the type
  Reference get refer {
    final functionParts = this.functionParts;
    if (functionParts != null) {
      return FunctionType(
        (b) => b
          ..isNullable = isNullable
          ..returnType = functionParts.returnType.refer
          ..requiredParameters.addAll(functionParts.requiredParameters.map((e) => e.refer))
          ..optionalParameters.addAll(functionParts.optionalParameters.map((e) => e.refer))
          ..namedParameters.addAll({
            for (final entry in functionParts.namedParameters.entries) entry.key: entry.value.refer,
          })
          ..namedRequiredParameters.addAll({
            for (final entry in functionParts.namedRequiredParameters.entries) entry.key: entry.value.refer,
          }),
      );
    }
    if (_isRecordType) {
      return RecordType(
        (b) => b
          ..url = import
          ..isNullable = isNullable
          ..positionalFieldTypes.addAll(typeArguments.where((e) => !e.isNamedRecordField).map((e) => e.refer))
          ..namedFieldTypes.addAll({
            for (final entry in typeArguments.where((e) => e.isNamedRecordField)) entry.nameInRecord!: entry.refer,
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
      identical(this, other) || other is ResolvedType && runtimeType == other.runtimeType && identity == other.identity;

  @override
  int get hashCode => import.hashCode ^ name.hashCode;

  /// serializes the type to json
  Map<String, dynamic> toJson() {
    return {
      'import': import,
      'name': name,
      'isNullable': isNullable,
      'isRecordType': _isRecordType,
      'nameInRecord': ?nameInRecord,
      if (typeArguments.isNotEmpty) 'typeArguments': typeArguments.map((e) => e.toJson()).toList(),
      'functionParts': ?functionParts?.toJson(),
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
  const FunctionTypeParts({
    required this.returnType,
    this.requiredParameters = const [],
    this.optionalParameters = const [],
    this.namedParameters = const {},
    this.namedRequiredParameters = const {},
  });

  /// deserializes the parts from json
  factory FunctionTypeParts.fromJson(Map<String, dynamic> map) {
    List<ResolvedType> list(String key) => [
      for (final e in map[key] as List<Object?>) ResolvedType.fromJson(e as Map<String, dynamic>),
    ];
    Map<String, ResolvedType> named(String key) => {
      for (final e in (map[key] as Map<String, dynamic>).entries)
        e.key: ResolvedType.fromJson(e.value as Map<String, dynamic>),
    };
    return FunctionTypeParts(
      returnType: ResolvedType.fromJson(map['returnType'] as Map<String, dynamic>),
      requiredParameters: list('requiredParameters'),
      optionalParameters: list('optionalParameters'),
      namedParameters: named('namedParameters'),
      namedRequiredParameters: named('namedRequiredParameters'),
    );
  }

  /// the return type
  final ResolvedType returnType;

  /// the types of the required positional parameters
  final List<ResolvedType> requiredParameters;

  /// the types of the optional positional parameters
  final List<ResolvedType> optionalParameters;

  /// the types of the optional named parameters, by name
  final Map<String, ResolvedType> namedParameters;

  /// the types of the required named parameters, by name
  final Map<String, ResolvedType> namedRequiredParameters;

  /// serializes the parts to json
  Map<String, dynamic> toJson() {
    return {
      'returnType': returnType.toJson(),
      'requiredParameters': requiredParameters.map((e) => e.toJson()).toList(),
      'optionalParameters': optionalParameters.map((e) => e.toJson()).toList(),
      'namedParameters': namedParameters.map((k, v) => MapEntry(k, v.toJson())),
      'namedRequiredParameters': namedRequiredParameters.map((k, v) => MapEntry(k, v.toJson())),
    };
  }
}
