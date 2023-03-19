import 'package:code_builder/code_builder.dart' show TypeReference;

class ResolvedType {
  String? import;
  String name;
  bool isNullable;
  List<ResolvedType> typeArguments;

  ResolvedType({
    required this.name,
    this.import,
    this.typeArguments = const [],
    this.isNullable = false,
  });

  String get identity => "$import#$name";

  TypeReference get refer {
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
      identical(this, other) ||
      other is ResolvedType &&
          runtimeType == other.runtimeType &&
          identity == other.identity;

  @override
  int get hashCode => import.hashCode ^ name.hashCode;

  ResolvedType copyWith({
    String? import,
    String? name,
    List<ResolvedType>? typeArguments,
    bool? isNullable,
  }) {
    return new ResolvedType(
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
      'typeArguments': this.typeArguments.map((e) => e.toJson()).toList(),
    };
  }

  factory ResolvedType.fromJson(Map<String, dynamic> map) {
    final typedArgs = <ResolvedType>[];
    if (map['typeArguments'] != null) {
      for (final arg in map['typeArguments']) {
        typedArgs.add(ResolvedType.fromJson(arg));
      }
    }
    return ResolvedType(
      import: map['import'] as String?,
      name: map['name'] as String,
      isNullable: map['isNullable'] as bool,
      typeArguments: typedArgs,
    );
  }
}
