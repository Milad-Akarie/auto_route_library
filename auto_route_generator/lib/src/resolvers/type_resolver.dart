import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart'
    show NullabilitySuffix;
import 'package:analyzer/dart/element/type.dart'
    show DartType, ParameterizedType;
import 'package:auto_route_generator/src/models/importable_type.dart';
import 'package:path/path.dart' as p;

class TypeResolver {
  final List<LibraryElement> libs;
  final Uri? targetFile;

  TypeResolver(this.libs, [this.targetFile]);

  String? resolveImport(Element? element) {
    // return early if source is null or element is a core type
    if (libs.isEmpty || element?.source == null || _isCoreDartType(element!)) {
      return null;
    }

    for (var lib in libs) {
      if (!_isCoreDartType(lib) &&
          lib.exportNamespace.definedNames.values.contains(element)) {
        return targetFile == null
            ? lib.identifier
            : _relative(
                lib.source.uri,
                targetFile!,
              );
      }
    }
    return null;
  }

  String _relative(Uri fileUri, Uri to) {
    var libName = to.pathSegments.first;
    if ((to.scheme == 'package' &&
            fileUri.scheme == 'package' &&
            fileUri.pathSegments.first == libName) ||
        (to.scheme == 'asset' && fileUri.scheme != 'package')) {
      if (fileUri.path == to.path) {
        return fileUri.pathSegments.last;
      } else {
        return p.posix
            .relative(fileUri.path, from: to.path)
            .replaceFirst('../', '');
      }
    } else {
      return fileUri.toString();
    }
  }

  bool _isCoreDartType(Element element) {
    return element.source?.fullName == 'dart:core';
  }

  List<ResolvedType> _resolveTypeArguments(DartType typeToCheck) {
    final types = <ResolvedType>[];
    if (typeToCheck is ParameterizedType) {
      for (DartType type in typeToCheck.typeArguments) {
        if (type.element is TypeParameterElement) {
          types.add(ResolvedType(name: 'dynamic'));
        } else {
          types.add(ResolvedType(
            name: type.element?.name ?? 'void',
            import: resolveImport(type.element),
            isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
            typeArguments: _resolveTypeArguments(type),
          ));
        }
      }
    }
    return types;
  }

  ResolvedType resolveFunctionType(ExecutableElement function) {
    final displayName = function.displayName.replaceFirst(RegExp('^_'), '');
    var functionName = displayName;
    Element elementToImport = function;
    if (function.enclosingElement is ClassElement) {
      functionName = '${function.enclosingElement.displayName}.$displayName';
      elementToImport = function.enclosingElement;
    }
    return ResolvedType(
      name: functionName,
      import: resolveImport(elementToImport),
    );
  }

  ResolvedType resolveType(DartType type) {
    return ResolvedType(
      name: type.element?.name ?? type.getDisplayString(withNullability: false),
      isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
      import: resolveImport(type.element),
      typeArguments: _resolveTypeArguments(type),
    );
  }
}
