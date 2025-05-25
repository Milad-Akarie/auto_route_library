import 'package:code_builder/code_builder.dart' show TypeReference, RecordType, Reference;

/// A class that represents a resolved type.
///
/// holds the type name, import, type arguments and nullability
class ResolvedType {
  /// the import path of the type
  String? import;

  /// the type name
  String name;

  /// whether the type is nullable
  bool isNullable;

  /// the type arguments
  List<ResolvedType> typeArguments;
  final bool _isRecordType;

  /// the name of the field in the record
  final String? nameInRecord;

  ResolvedType._({
    required this.name,
    this.import,
    this.typeArguments = const [],
    this.isNullable = false,
    required bool isRecordType,
    this.nameInRecord,
  }) : _isRecordType = isRecordType;

  /// Default constructor
  ResolvedType({
    required this.name,
    this.import,
    this.typeArguments = const [],
    this.isNullable = false,
    this.nameInRecord,
  }) : _isRecordType = false;

  /// Constructor for a record types
  ResolvedType.record({
    required this.name,
    this.import,
    this.typeArguments = const [],
    this.isNullable = false,
    this.nameInRecord,
  }) : _isRecordType = true;

  /// the unique identity of the type
  String get identity => "$import#$name";

  /// whether the type is for a named record field
  bool get isNamedRecordField => nameInRecord != null;

  /// Creates a [TypeReference] from the type
  Reference get refer {
    if (_isRecordType) {
      return RecordType(
        (b) => b
          ..url = import
          ..isNullable = isNullable
          ..positionalFieldTypes.addAll(
            typeArguments.where((e) => !e.isNamedRecordField).map((e) => e.refer),
          )
          ..namedFieldTypes.addAll({
            for (final entry in [...typeArguments.where((e) => e.isNamedRecordField)]) entry.nameInRecord!: entry.refer
          }),
      );
    }
    return TypeReference((b) => b
      ..symbol = name
      ..url = import
      ..isNullable = isNullable
      ..types.addAll(typeArguments.map((e) => e.refer)));
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
      if (nameInRecord != null) 'nameInRecord': nameInRecord,
      if (typeArguments.isNotEmpty) 'typeArguments': typeArguments.map((e) => e.toJson()).toList(),
    };
  }

  /// deserializes the type from json
  factory ResolvedType.fromJson(Map<String, dynamic> map) {
    final typedArgs = <ResolvedType>[];
    if (map['typeArguments'] != null) {
      for (final arg in map['typeArguments']) {
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
    );
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
