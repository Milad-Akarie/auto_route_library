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

  bool get hasRoutePageAnnotation => metadata.any((e) => e.isRoutePage);

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

  Set<String> get nonCoreIdentifiers => {
        ...routePageAnnotation.typeArgsIdentifiers,
        for (final param in defaultConstructorParams) ...?param.type?.identifiers,
      }.whereNot(dartCoreTypeNames.contains).toSet();
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

  List<TypeAnnotation> get typeArgs => [...?this.typeArguments?.arguments];

  Iterable<Expression> get args => [...?arguments?.arguments.toList()];

  Set<String> get typeArgsIdentifiers => {...typeArgs.expand((e) => e.identifiers)};

  Iterable<NamedExpression> get namedArgs => args.whereType<NamedExpression>();

  NamedExpression? getNamedArg(String name) => namedArgs.firstWhereOrNull((e) => e.name.label.name == name);

  bool hasNamedConstructor(String constructorName) {
    final nameIdentifier = name;
    if (nameIdentifier is PrefixedIdentifier) {
      return nameIdentifier.identifier.name == constructorName;
    }
    return false;
  }

  String? getNamedString(String name) {
    final arg = getNamedArg(name);
    if (arg == null) return null;
    final expression = arg.expression;
    if (expression is StringLiteral) {
      return expression.stringValue;
    } else {
      throw ArgumentError('[$name] must be a string literal');
    }
  }

  String? getPositionalString(int index) {
    final arg = args.elementAtOrNull(index);
    if (arg == null) return null;
    final expression = arg;
    if (expression is StringLiteral) {
      return expression.stringValue;
    } else {
      throw ArgumentError('Argument [$index] must be a string literal');
    }
  }

  bool? getNamedBool(String name) {
    final arg = getNamedArg(name);
    if (arg == null) return null;
    final expression = arg.expression;
    if (expression is BooleanLiteral) {
      return expression.value;
    } else {
      throw ArgumentError('[$name] must be a boolean literal');
    }
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

  Annotation? getAnnotation(String identifier) {
    return annotations.firstWhereOrNull((e) {
      return switch (e.name) {
        SimpleIdentifier s => s.name == identifier,
        PrefixedIdentifier p => p.prefix.name == identifier,
        LibraryIdentifier l => l.components.last.name == identifier,
      };
    });
  }
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

extension CompilationUnitX on CompilationUnit {
  List<ImportDirective> get imports => List.of(directives.whereType<ImportDirective>());

  Iterable<ClassDeclaration> get classes => declarations.whereType<ClassDeclaration>();

  List<Uri> importUris(String rootPackage) => imports.where((e) => e.uri.stringValue != null).map((e) {
        return Uri.parse(e.uri.stringValue!);
      }).sortedBy<num>((e) {
        final package = e.pathSegments.first;
        if (package == 'flutter') return 1;
        return !e.hasScheme || package == rootPackage ? -1 : 0;
      }).toList();

  int calculateUpdatableHash() {
    var calculatedHash = imports.fold(0, (acc, a) => acc ^ a.toSource().hashCode);
    for (final clazz in declarations.where((e) => e.metadata.isNotEmpty)) {
      for (final child in clazz.childEntities.whereType<ClassMember>()) {
        if (child is ConstructorDeclaration || child is FieldDeclaration) {
          calculatedHash = calculatedHash ^ child.toSource().hashCode;
        }
        final routePageMeta = clazz.metadata.firstWhereOrNull((e) => e.name.name == 'RoutePage');
        if (routePageMeta != null) {
          calculatedHash = calculatedHash ^ routePageMeta.toSource().hashCode;
        }
      }
    }
    return calculatedHash;
  }
}
