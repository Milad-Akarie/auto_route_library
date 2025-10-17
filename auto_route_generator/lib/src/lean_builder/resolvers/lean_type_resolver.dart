import 'package:auto_route_generator/src/models/resolved_type.dart';
import 'package:lean_builder/builder.dart';

import 'package:lean_builder/type.dart';
import 'package:path/path.dart' as p;

/// A Helper class that resolves types
class LeanTypeResolver {
  /// The target file to resolve relative paths to
  final Uri? targetFile;
  final Resolver _resolver;

  /// Default constructor
  LeanTypeResolver(this._resolver, [this.targetFile]);

  /// Resolved the import path of the given [element]
  String? resolveImport(DartType? type) {
    // return early if source is null
    if (type == null || type is! NamedDartType) {
      return null;
    }
    final uri = _resolver.uriForAsset(type.declarationRef.providerId);
    // return early if the element is from core dart library
    if (_isCoreDartType(uri)) return null;
    // handles dart:xxx.xxx.dart imports
    if (uri.scheme == 'dart' && uri.pathSegments.length > 1) {
      return 'dart:${uri.pathSegments.first}';
    }

    if (uri.scheme == 'asset') {
      return _assetToPackage(uri);
    }
    return targetFile == null ? uri.toString() : _relative(uri, targetFile!);
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

  bool _isCoreDartType(Uri uri) {
    return uri.scheme == 'dart' && uri.pathSegments.firstOrNull == 'core';
  }

  List<ResolvedType> _resolveTypeArguments(DartType typeToCheck) {
    final types = <ResolvedType>[];
    if (typeToCheck is RecordType) {
      for (final recordField in typeToCheck.positionalFields) {
        types.add(ResolvedType(
          name: recordField.type.name ?? 'void',
          import: resolveImport(recordField.type),
          isNullable: recordField.type.isNullable,
          typeArguments: _resolveTypeArguments(recordField.type),
        ));
      }
      for (final recordField in typeToCheck.namedFields) {
        types.add(ResolvedType(
          name: recordField.type.name ?? 'void',
          import: resolveImport(recordField.type),
          isNullable: recordField.type.isNullable,
          typeArguments: _resolveTypeArguments(recordField.type),
          nameInRecord: recordField.name,
        ));
      }
    } else if (typeToCheck is ParameterizedType) {
      for (DartType type in typeToCheck.typeArguments) {
        if (type is RecordType) {
          types.add(ResolvedType.record(
            name: type.name ?? 'void',
            import: resolveImport(type),
            isNullable: type.isNullable,
            typeArguments: _resolveTypeArguments(type),
          ));
        } else if (type.element is TypeParameterType) {
          types.add(ResolvedType(name: 'dynamic'));
        } else {
          types.add(ResolvedType(
            name: type.element?.name ?? 'void',
            import: resolveImport(type),
            isNullable: type.isNullable,
            typeArguments: _resolveTypeArguments(type),
          ));
        }
      }
    }
    return types;
  }

  /// Resolves the given [type] to a [ResolvedType]
  ResolvedType resolveType(DartType type) {
    final import = resolveImport(type);
    final typeArgs = <ResolvedType>[];
    typeArgs.addAll(_resolveTypeArguments(type));

    if (type is RecordType) {
      return ResolvedType.record(
        name: type.name ?? 'void',
        import: import,
        isNullable: type.isNullable,
        typeArguments: typeArgs,
      );
    }

    return ResolvedType(
      name: type.name ?? 'void',
      isNullable: type.isNullable,
      import: import,
      typeArguments: typeArgs,
    );
  }
}
