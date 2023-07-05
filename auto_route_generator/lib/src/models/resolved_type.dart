import 'package:code_builder/code_builder.dart' show TypeReference, RecordType, Reference;

class ResolvedType {
  String? import;
  String name;
  bool isNullable;
  List<ResolvedType> typeArguments;
  final bool _isRecordType;
  final String? nameInRecord;

  ResolvedType._({
    required this.name,
    this.import,
    this.typeArguments = const [],
    this.isNullable = false,
    required bool isRecordType,
    this.nameInRecord,
  }) : _isRecordType = isRecordType;

  ResolvedType({
    required this.name,
    this.import,
    this.typeArguments = const [],
    this.isNullable = false,
    this.nameInRecord,
  })  : _isRecordType = false;

  ResolvedType.record({
    required this.name,
    this.import,
    this.typeArguments = const [],
    this.isNullable = false,
    this.nameInRecord,
  }) : _isRecordType = true;

  String get identity => "$import#$name";

  bool get isNamedRecordField => nameInRecord != null;

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

  ResolvedType copyWith({
    String? import,
    String? name,
    List<ResolvedType>? typeArguments,
    bool? isNullable,
  }) {
    return ResolvedType(
      import: import ?? this.import,
      name: name ?? this.name,
      isNullable: isNullable ?? this.isNullable,
      typeArguments: typeArguments ?? this.typeArguments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'import': this.import,
      'name': this.name,
      'isNullable': this.isNullable,
      'isRecordType': this._isRecordType,
      if (nameInRecord != null) 'nameInRecord': this.nameInRecord,
      if (typeArguments.isNotEmpty) 'typeArguments': this.typeArguments.map((e) => e.toJson()).toList(),
    };
  }

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
}
