import 'package:analyzer/dart/ast/ast.dart';
import 'package:collection/collection.dart';

const _dartCoreTypeNames = <String>{
  'bool',
  'int',
  'double',
  'num',
  'String',
  'List',
  'Map',
  'Set',
  'Iterable',
  'void',
  'dynamic',
  'Object',
  'Function',
  'Null',
  'Type',
  'Symbol',
};

extension ClassDeclarationX on ClassDeclaration {
  Iterable<FieldDeclaration> get fields => members.whereType<FieldDeclaration>();

  Iterable<ConstructorDeclaration> get constructors => members.whereType<ConstructorDeclaration>();
}

extension ConstructorDeclarationX on ConstructorDeclaration {
  List<FormalParameter> get parametersList => parameters.parameters.toList();

  bool get hasParameters => parametersList.isNotEmpty;
}

extension FormalParameterX on FormalParameter {
  String? get paramName => name?.lexeme;

  TypeAnnotation? get paramType => switch (this) {
        FieldFormalParameter f => f.type,
        SimpleFormalParameter s => s.type,
        DefaultFormalParameter d => d.parameter.paramType,
        _ => null,
      };

  List<Annotation> get annotations => metadata.toList();

  bool hasAnnotation(String identifier) => annotations.any((e) => e.name.name == identifier);

  Annotation? getAnnotation(String identifier) => annotations.firstWhereOrNull((e) => e.name.name == identifier);
}

extension FieldDeclarationX on FieldDeclaration {
  String get name => fields.variables.first.name.lexeme;

  TypeAnnotation? get type => fields.type;

  String? get typeName => type?.name;

  bool get isPrivate => name.startsWith('_');

  bool get isNamed => fields.variables.length > 1;
}

extension TypeAnnotationX on TypeAnnotation {
  String get name => this is NamedType ? (this as NamedType).name2.lexeme : toSource();

  bool get isDartCoreType => _dartCoreTypeNames.contains(name);

  bool get isGeneric => typeArguments.isNotEmpty;

  bool get isNullable => question != null;

  bool get isFunction => this is GenericFunctionType;

  List<TypeAnnotation> get typeArguments => (this as NamedType).typeArguments?.arguments ?? [];
}

extension DirectiveX on UriBasedDirective {
  Uri get pathUri => Uri.parse(uri.stringValue!);
}
