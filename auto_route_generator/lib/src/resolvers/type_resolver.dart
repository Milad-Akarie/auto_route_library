import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart' show NullabilitySuffix;
import 'package:analyzer/dart/element/type.dart' show DartType, ParameterizedType, RecordType;
import 'package:auto_route_generator/build_utils.dart';
import 'package:auto_route_generator/src/models/resolved_type.dart';
import 'package:path/path.dart' as p;

const _unPreferredImports = {'dart:ui'};

/// A Helper class that resolves types
class TypeResolver {
  /// The list of resolved libraries in [BuildStep]
  final List<LibraryElement2> libs;

  /// The target file to resolve relative paths to
  final Uri? targetFile;

  /// Default constructor
  TypeResolver(this.libs, [this.targetFile]);

  /// Resolved the import path of the given [element]
  String? resolveImport(Element2? element) {
    // return early if source is null or element is a core type
    if (libs.isEmpty || element?.library2?.uri == null || _isCoreDartType(element!)) {
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

  bool _isCoreDartType(Element2 element) {
    return element.library2?.uri.toString() == 'dart:core';
  }

  List<ResolvedType> _resolveTypeArguments(DartType typeToCheck) {
    final types = <ResolvedType>[];
    if (typeToCheck is RecordType) {
      for (final recordField in typeToCheck.positionalFields) {
        types.add(ResolvedType(
          name: recordField.type.element3?.displayName ?? 'void',
          import: resolveImport(recordField.type.element3),
          isNullable: recordField.type.nullabilitySuffix == NullabilitySuffix.question,
          typeArguments: _resolveTypeArguments(recordField.type),
        ));
      }
      for (final recordField in typeToCheck.namedFields) {
        types.add(ResolvedType(
          name: recordField.type.element3?.displayName ?? 'void',
          import: resolveImport(recordField.type.element3),
          isNullable: recordField.type.nullabilitySuffix == NullabilitySuffix.question,
          typeArguments: _resolveTypeArguments(recordField.type),
          nameInRecord: recordField.name,
        ));
      }
    } else if (typeToCheck is ParameterizedType) {
      for (DartType type in typeToCheck.typeArguments) {
        if (type is RecordType) {
          types.add(ResolvedType.record(
            name: type.nameWithoutSuffix,
            import: resolveImport(type.element),
            isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
            typeArguments: _resolveTypeArguments(type),
          ));
        } else if (type.element3 is TypeParameterElement2) {
          types.add(ResolvedType(name: 'dynamic'));
        } else {
          types.add(ResolvedType(
            name: type.element3?.displayName ?? 'void',
            import: resolveImport(type.element3),
            isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
            typeArguments: _resolveTypeArguments(type),
          ));
        }
      }
    }
    return types;
  }

  /// Resolves the given [type] to a [ResolvedType]
  ResolvedType resolveType(DartType type) {
    final effectiveElement = type.alias?.element2 ?? type.element3;
    final import = resolveImport(effectiveElement);
    final typeArgs = <ResolvedType>[];
    final alias = type.alias;
    if (alias != null) {
      typeArgs.addAll(alias.typeArguments.map(resolveType));
    } else {
      typeArgs.addAll(_resolveTypeArguments(type));
    }
    if (type is RecordType && type.alias == null) {
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
