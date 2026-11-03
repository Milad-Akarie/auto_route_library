import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart' show NullabilitySuffix;
import 'package:analyzer/dart/element/type.dart' show DartType, FunctionType, ParameterizedType, RecordType;
import 'package:auto_route_generator/build_utils.dart';
import 'package:auto_route_generator/src/models/resolved_type.dart';
import 'package:path/path.dart' as p;

const _unPreferredImports = {'dart:ui'};

/// A Helper class that resolves types
class TypeResolver {
  /// The list of resolved libraries in [BuildStep]
  final List<LibraryElement> libs;

  /// The target file to resolve relative paths to
  final Uri? targetFile;

  /// Default constructor
  TypeResolver(this.libs, [this.targetFile]);

  /// Resolved the import path of the given [element]
  String? resolveImport(Element? element) {
    // return early if source is null or element is a core type
    if (libs.isEmpty || element?.library?.uri == null || _isCoreDartType(element!)) {
      return null;
    }

    final fallBackImports = <String>{};
    for (var lib in libs) {
      if (!_isCoreDartType(lib) && lib.exportNamespace.definedNames2.values.contains(element)) {
        final uri = lib.uri;
        if (_unPreferredImports.contains(uri.toString())) {
          fallBackImports.add(uri.toString());
          continue;
        }
        if (uri.scheme == 'asset') {
          return _assetToPackage(lib.uri);
        }
        return targetFile == null ? lib.uri.toString() : _relative(uri, targetFile!);
      }
    }
    return fallBackImports.firstOrNull;
  }

  String _assetToPackage(Uri uri) {
    if (uri.scheme == 'asset') {
      final validSegments = <String>[];
      for (var i = 0; i < uri.pathSegments.length; i++) {
        if (uri.pathSegments[i] == 'lib') {
          if (i > 0 && i + 1 < uri.pathSegments.length) {
            validSegments.add(uri.pathSegments[i - 1]);
            validSegments.addAll(uri.pathSegments.sublist(i + 1));
            return 'package:${validSegments.join('/')}';
          }
          break;
        }
      }
    }
    return uri.toString();
  }

  String _relative(Uri fileUri, Uri to) {
    var libName = to.pathSegments.first;
    if ((to.scheme == 'package' && fileUri.scheme == 'package' && fileUri.pathSegments.first == libName) ||
        (to.scheme == 'asset' && fileUri.scheme != 'package')) {
      if (fileUri.path == to.path) {
        return fileUri.pathSegments.last;
      } else {
        return p.posix.relative(fileUri.path, from: to.path).replaceFirst('../', '');
      }
    } else {
      return fileUri.toString();
    }
  }

  bool _isCoreDartType(Element element) {
    return element.library?.uri.toString() == 'dart:core';
  }

  List<ResolvedType> _resolveTypeArguments(DartType typeToCheck) {
    final types = <ResolvedType>[];
    if (typeToCheck is RecordType) {
      for (final recordField in typeToCheck.positionalFields) {
        types.add(_resolveNestedType(recordField.type));
      }
      for (final recordField in typeToCheck.namedFields) {
        types.add(_resolveNestedType(recordField.type, nameInRecord: recordField.name));
      }
    } else if (typeToCheck is ParameterizedType) {
      for (DartType type in typeToCheck.typeArguments) {
        types.add(_resolveNestedType(type));
      }
    }
    return types;
  }

  /// Resolves a type argument or a record field, which may be a record or a
  /// function type itself.
  ResolvedType _resolveNestedType(DartType type, {String? nameInRecord}) {
    if (type is FunctionType && type.alias == null) {
      return ResolvedType.function(
        parts: FunctionTypeParts(
          returnType: _resolveNestedType(type.returnType),
          requiredParameters: [
            for (final p in type.formalParameters.where((p) => p.isRequiredPositional)) _resolveNestedType(p.type),
          ],
          optionalParameters: [
            for (final p in type.formalParameters.where((p) => p.isOptionalPositional)) _resolveNestedType(p.type),
          ],
          namedParameters: {
            for (final p in type.formalParameters.where((p) => p.isOptionalNamed)) p.name!: _resolveNestedType(p.type),
          },
          namedRequiredParameters: {
            for (final p in type.formalParameters.where((p) => p.isRequiredNamed)) p.name!: _resolveNestedType(p.type),
          },
        ),
        isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
        nameInRecord: nameInRecord,
      );
    } else if (type is FunctionType) {
      final alias = type.alias!;
      return ResolvedType(
        name: alias.element.displayName,
        import: resolveImport(alias.element),
        isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
        typeArguments: alias.typeArguments.map(resolveType).toList(),
        nameInRecord: nameInRecord,
      );
    } else if (type is RecordType) {
      return ResolvedType.record(
        name: type.nameWithoutSuffix,
        import: resolveImport(type.element),
        isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
        typeArguments: _resolveTypeArguments(type),
        nameInRecord: nameInRecord,
      );
    } else if (type.element is TypeParameterElement) {
      return ResolvedType(name: 'dynamic', nameInRecord: nameInRecord);
    }
    return ResolvedType(
      name: type.element?.displayName ?? 'void',
      import: resolveImport(type.element),
      isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
      typeArguments: _resolveTypeArguments(type),
      nameInRecord: nameInRecord,
    );
  }

  /// Resolves the given [type] to a [ResolvedType]
  ///
  /// A type named by a typedef resolves to the typedef, unless [skipAlias]
  /// is true: then it resolves to the type the typedef stands for.
  ResolvedType resolveType(DartType type, {bool skipAlias = false}) {
    final alias = skipAlias ? null : type.alias;
    final effectiveElement = alias?.element ?? type.element;
    final import = resolveImport(effectiveElement);
    final typeArgs = <ResolvedType>[];
    if (alias != null) {
      typeArgs.addAll(alias.typeArguments.map(resolveType));
    } else {
      typeArgs.addAll(_resolveTypeArguments(type));
    }
    if (type is RecordType && alias == null) {
      return ResolvedType.record(
        name: effectiveElement?.displayName ?? 'void',
        import: import,
        isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
        typeArguments: typeArgs,
      );
    }

    return ResolvedType(
      name: effectiveElement?.displayName ?? type.nameWithoutSuffix,
      isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
      import: import,
      typeArguments: typeArgs,
    );
  }
}
