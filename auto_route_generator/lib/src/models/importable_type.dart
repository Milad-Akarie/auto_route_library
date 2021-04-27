import 'package:code_builder/code_builder.dart' show TypeReference;

class ImportableType {
  String? import;
  String name;
  bool isNullable;
  List<ImportableType> typeArguments;

  ImportableType({
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
      other is ImportableType &&
          runtimeType == other.runtimeType &&
          identity == other.identity;

  @override
  int get hashCode => import.hashCode ^ name.hashCode;

  ImportableType copyWith({
    String? import,
    String? name,
    List<ImportableType>? typeArguments,
    bool? isNullable,
  }) {
    return new ImportableType(
      import: import ?? this.import,
      name: name ?? this.name,
      isNullable: isNullable ?? this.isNullable,
      typeArguments: typeArguments ?? this.typeArguments,
    );
  }
}
