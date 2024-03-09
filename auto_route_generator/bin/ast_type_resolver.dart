import 'package:analyzer/dart/ast/ast.dart';
import 'package:auto_route_generator/src/models/resolved_type.dart';

import 'ast_extensions.dart';
import 'package_file_resolver.dart';

/// A Helper class that resolves types
class AstTypeResolver {
  /// The list of resolved libraries in [BuildStep]
  final Map<String, Set<String>> libs;

  final PackageFileResolver resolver;

  /// Default constructor
  AstTypeResolver(this.libs, this.resolver);

  /// Resolved the import path of the given [element]
  String? resolveImport(String? identifier) {
    // return early if source is null or element is a core type
    if (libs.isEmpty || identifier == null) {
      return null;
    }
    for (var lib in libs.entries) {
      if (libs.values.contains(identifier)) {
        return resolver.uriToPackage(Uri.parse(lib.key));
      }
    }
    return null;
  }

  List<ResolvedType> _resolveTypeArguments(TypeAnnotation typeToCheck) {
    final types = <ResolvedType>[];
    if (typeToCheck is RecordTypeAnnotation) {
      for (final recordField in typeToCheck.positionalFields) {
        types.add(ResolvedType(
          name: recordField.type.name ?? 'void',
          import: resolveImport(recordField.type.name),
          isNullable: recordField.type.isNullable,
          typeArguments: _resolveTypeArguments(recordField.type),
        ));
      }
      for (final recordField in [...?typeToCheck.namedFields?.fields]) {
        types.add(ResolvedType(
          name: recordField.type.name ?? 'void',
          import: resolveImport(recordField.type.name),
          isNullable: recordField.type.isNullable,
          typeArguments: _resolveTypeArguments(recordField.type),
          nameInRecord: recordField.name.lexeme,
        ));
      }
    } else if (typeToCheck.isGeneric) {
      for (TypeAnnotation type in typeToCheck.typeArgumentsList) {
        if (type is RecordTypeAnnotation) {
          types.add(ResolvedType.record(
            name: type.name ?? 'void',
            import: resolveImport(type.name),
            isNullable: type.isNullable,
            typeArguments: _resolveTypeArguments(type),
          ));
        } else {
          types.add(ResolvedType(
            name: type.name ?? 'void',
            import: resolveImport(type.name),
            isNullable: type.isNullable,
            typeArguments: _resolveTypeArguments(type),
          ));
        }
      }
    }
    return types;
  }

  /// Resolves the given [type] to a [ResolvedType]
  ResolvedType resolveType(TypeAnnotation type) {
    if (type is RecordTypeAnnotation) {
      return ResolvedType.record(
        name: type.name ?? 'void',
        import: resolveImport(type.name),
        isNullable: type.isNullable,
        typeArguments: _resolveTypeArguments(type),
      );
    }
    return ResolvedType(
      name: type.name ?? 'dynamic',
      isNullable: type.isNullable,
      import: resolveImport(type.name),
      typeArguments: _resolveTypeArguments(type),
    );
  }
}
