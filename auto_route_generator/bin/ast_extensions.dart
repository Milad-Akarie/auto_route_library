import 'package:analyzer/dart/ast/ast.dart';
import 'package:collection/collection.dart';

const dartCoreTypeNames = <String>{
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

const _routePageAnnotation = 'RoutePage';

extension ClassDeclarationX on ClassDeclaration {
  Iterable<FieldDeclaration> get fields => members.whereType<FieldDeclaration>();

  bool get hasRoutePageAnnotation => metadata.any((e) => e.name.name == _routePageAnnotation);

  Iterable<ConstructorDeclaration> get constructors => members.whereType<ConstructorDeclaration>();

  bool get hasDefaultConstructor => defaultConstructor != null;

  ConstructorDeclaration? get defaultConstructor => constructors.firstWhereOrNull((e) => e.name == null);

  Annotation get routePageAnnotation => metadata.firstWhere((e) => e.isRoutePage);

  List<TypedParam> get defaultConstructorParams {
    if (defaultConstructor == null) return [];
    final params = <TypedParam>[];
    for (final param in defaultConstructor!.parameters.parameters) {
      final type = param.paramType ?? fields.firstWhereOrNull((e) => e.name == param.paramName)?.type;
      params.add(TypedParam(param, type));
    }
    return params;
  }
}

extension FormalParameterListX on FormalParameterList {
  List<TypedParam> get typedParams {
    return parameters.map((e) {
      final type = e.paramType;
      return TypedParam(e, type);
    }).toList();
  }
}

extension AnnotationX on Annotation {
  bool get isRoutePage => this.name.name == _routePageAnnotation;

  List<TypeAnnotation> get returnTypeArgs => this.typeArguments?.arguments.toList() ?? const [];

  Set<String> get returnIdentifiers => {...returnTypeArgs.expand((e) => e.identifiers)};

  bool? getBoolValue(String name) {
    return false;
    // final arg = arguments?.arguments.toList().firstWhereOrNull((e) => e.name?.name == name);
    // return arg?.value is BooleanLiteral ? (arg!.value as BooleanLiteral).value : null;
  }

  String? getStringValue(String name) {
    return null;
    // final arg = arguments?.arguments.toList().firstWhereOrNull((e) => e.name?.name == name);
    // return arg?.value is StringLiteral ? (arg!.value as StringLiteral).stringValue : null;
  }
}

extension ConstructorDeclarationX on ConstructorDeclaration {}

class TypedParam {
  final FormalParameter param;
  final TypeAnnotation? type;

  Annotation? get pathParamAnnotation => param.getAnnotation('PathParam');

  Annotation? get queryParamAnnotation => param.getAnnotation('QueryParam');

  String get name => param.paramName ?? '';

  bool get isNamed => param.isNamed;

  bool get isPositional => param.isPositional;

  bool get isOptional => param.isOptional;

  bool get isRequiredNamed => param.isRequiredNamed;

  bool get isSuper => param.actual is SuperFormalParameter;

  bool get isThis => param.actual is FieldFormalParameter;

  String? get defaultValueCode =>
      param is DefaultFormalParameter ? (param as DefaultFormalParameter).defaultValue?.toSource() : null;
  TypedParam(this.param, this.type);
}

extension FormalParameterX on FormalParameter {
  String? get paramName => name?.lexeme;

  TypeAnnotation? get paramType => switch (this) {
        FieldFormalParameter f => f.type,
        SimpleFormalParameter s => s.type,
        DefaultFormalParameter d => d.parameter.paramType,
        _ => null,
      };

  FormalParameter get actual => switch (this) {
        DefaultFormalParameter d => d.parameter,
        _ => this,
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

extension TypeAnnotationX on TypeAnnotation? {
  String? get name => this is NamedType ? (this as NamedType).name2.lexeme : this?.toSource();

  bool get isDartCoreType => dartCoreTypeNames.contains(name);

  bool get isGeneric => typeArgumentsList.isNotEmpty;

  bool get isNullable => this?.question != null;

  bool get isFunction => this is GenericFunctionType;

  List<TypeAnnotation> get typeArgumentsList => switch (this) {
        NamedType n => [...?n.typeArguments?.arguments],
        _ => const [],
      };

  Set<String> get identifiers {
    return switch (this) {
      NamedType n => {n.name2.lexeme, ...n.typeArgumentsList.expand((e) => e.identifiers)},
      GenericFunctionType f => {
          ...f.returnType.identifiers,
          ...f.parameters.parameters.expand((e) => {...?e.paramType?.identifiers})
        },
      RecordTypeAnnotation r => {
          ...?r.namedFields?.fields.toList().expand((e) => e.type.identifiers),
          ...r.positionalFields.toList().expand((e) => e.type.identifiers)
        },
      _ => const {},
    };
  }
}

extension DirectiveX on UriBasedDirective {
  Uri get pathUri => Uri.parse(uri.stringValue!);
}

///    compilationUnitMember ::=
///        [ClassDeclaration]
///      | [MixinDeclaration]
///      | [ExtensionDeclaration]
///      | [EnumDeclaration]
///      | [TypeAlias]
///      | [FunctionDeclaration]
///      | [TopLevelVariableDeclaration]
extension CompilationUnitMemberX on CompilationUnitMember {
  String get name => switch (this) {
        ClassDeclaration c => c.name.lexeme,
        MixinDeclaration m => m.name.lexeme,
        ExtensionDeclaration e => e.name?.lexeme ?? '',
        EnumDeclaration e => e.name.lexeme,
        TypeAlias t => t.name.lexeme,
        FunctionDeclaration f => f.name.lexeme,
        TopLevelVariableDeclaration v => v.variables.variables.first.name.lexeme,
        _ => '',
      };
}