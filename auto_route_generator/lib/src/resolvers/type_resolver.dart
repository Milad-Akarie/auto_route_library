import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart' show DartType, FunctionType, ParameterizedType, RecordType;
import 'package:auto_route_generator/build_utils.dart';
import 'package:auto_route_generator/src/models/resolved_type.dart';
import 'package:path/path.dart' as p;

const _kUnPreferredImports = {'dart:ui'};

/// A Helper class that resolves types
class TypeResolver {
  /// Default constructor
  const new(this._libs, [this._targetFile]);

  /// The list of resolved libraries in `BuildStep`
  final List<LibraryElement> _libs;

  /// The target file to resolve relative paths to
  final Uri? _targetFile;

  /// Resolved the import path of the given [element]
  String? resolveImport(Element? element) {
    // return early if source is null or element is a core type
    if (_libs.isEmpty || element?.library?.uri == null || _isCoreDartType(element!)) {
      return null;
    }

    final fallBackImports = <String>{};
    for (final lib in _libs) {
      if (!_isCoreDartType(lib) && lib.exportNamespace.definedNames2.values.contains(element)) {
        final uri = lib.uri;
        if (_kUnPreferredImports.contains(uri.toString())) {
          fallBackImports.add(uri.toString());
          continue;
        }
        if (uri.scheme == 'asset') {
          return _assetToPackage(lib.uri);
        }
        return _targetFile == null ? lib.uri.toString() : _relative(uri, _targetFile!);
      }
    }
    return fallBackImports.firstOrNull;
  }

  String _assetToPackage(Uri uri) {
    if (uri.scheme == 'asset') {
      final segments = uri.pathSegments;
      final libIndex = segments.indexOf('lib');
      if (libIndex > 0 && libIndex + 1 < segments.length) {
        final validSegments = [...segments.sublist(libIndex - 1, libIndex), ...segments.sublist(libIndex + 1)];
        return 'package:${validSegments.join('/')}';
      }
    }
    return uri.toString();
  }

  String _relative(Uri fileUri, Uri to) {
    final libName = to.pathSegments.firstOrNull;
    if ((to.scheme == 'package' && fileUri.scheme == 'package' && fileUri.pathSegments.firstOrNull == libName) ||
        (to.scheme == 'asset' && fileUri.scheme != 'package')) {
      if (fileUri.path == to.path) {
        return p.posix.basename(fileUri.path);
      }
      return p.posix.relative(fileUri.path, from: to.path).replaceFirst('../', '');
    }
    return fileUri.toString();
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
      for (final type in typeToCheck.typeArguments) {
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
            for (final p in type.formalParameters.where((parameter) => parameter.isRequiredPositional))
              _resolveNestedType(p.type),
          ],
          optionalParameters: [
            for (final p in type.formalParameters.where((parameter) => parameter.isOptionalPositional))
              _resolveNestedType(p.type),
          ],
          namedParameters: {
            for (final p in type.formalParameters.where((parameter) => parameter.isOptionalNamed))
              p.name!: _resolveNestedType(p.type),
          },
          namedRequiredParameters: {
            for (final p in type.formalParameters.where((parameter) => parameter.isRequiredNamed))
              p.name!: _resolveNestedType(p.type),
          },
        ),
        isNullable: type.nullabilitySuffix == .question,
        nameInRecord: nameInRecord,
      );
    } else if (type is FunctionType) {
      final alias = type.alias!;
      return ResolvedType(
        name: alias.element.displayName,
        import: resolveImport(alias.element),
        isNullable: type.nullabilitySuffix == .question,
        typeArguments: alias.typeArguments.map(resolveType).toList(),
        nameInRecord: nameInRecord,
      );
    } else if (type is RecordType) {
      return ResolvedType.record(
        name: type.nameWithoutSuffix,
        import: resolveImport(type.element),
        isNullable: type.nullabilitySuffix == .question,
        typeArguments: _resolveTypeArguments(type),
        nameInRecord: nameInRecord,
      );
    } else if (type.element case final TypeParameterElement element) {
      // A type parameter of the page class is one the route declares too.
      // Any other, such as a generic function's, has no name there.
      if (element.enclosingElement is! InterfaceElement) {
        return ResolvedType(name: 'dynamic', nameInRecord: nameInRecord);
      }
      return ResolvedType(
        name: element.displayName,
        isNullable: type.nullabilitySuffix == .question,
        nameInRecord: nameInRecord,
      );
    }
    return ResolvedType(
      name: type.element?.displayName ?? 'void',
      import: resolveImport(type.element),
      isNullable: type.nullabilitySuffix == .question,
      typeArguments: _resolveTypeArguments(type),
      nameInRecord: nameInRecord,
      isEnum: type.element is EnumElement,
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
        isNullable: type.nullabilitySuffix == .question,
        typeArguments: typeArgs,
      );
    }

    return ResolvedType(
      name: effectiveElement?.displayName ?? type.nameWithoutSuffix,
      isNullable: type.nullabilitySuffix == .question,
      import: import,
      typeArguments: typeArgs,
      isEnum: effectiveElement is EnumElement,
    );
  }
}
