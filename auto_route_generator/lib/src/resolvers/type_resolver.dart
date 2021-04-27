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

  TypeResolver(this.libs, this.targetFile);

  String? resolveImport(Element? element) {
    // return early if source is null or element is a core type
    if (element?.source == null || _isCoreDartType(element!)) {
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

  List<ImportableType> _resolveTypeArguments(DartType typeToCheck) {
    final importableTypes = <ImportableType>[];
    if (typeToCheck is ParameterizedType) {
      for (DartType type in typeToCheck.typeArguments) {
        if (type.element is TypeParameterElement) {
          importableTypes.add(ImportableType(name: 'dynamic'));
        } else {
          importableTypes.add(ImportableType(
            name: type.element?.name ?? 'void',
            import: resolveImport(type.element),
            typeArguments: _resolveTypeArguments(type),
          ));
        }
      }
    }
    return importableTypes;
  }

  ImportableType resolveImportableFunctionType(ExecutableElement function) {
    final displayName = function.displayName.replaceFirst(RegExp('^_'), '');
    var functionName = displayName;
    Element elementToImport = function;
    if (function.enclosingElement is ClassElement) {
      functionName = '${function.enclosingElement.displayName}.$displayName';
      elementToImport = function.enclosingElement;
    }
    return ImportableType(
      name: functionName,
      import: resolveImport(elementToImport),
    );
  }

  ImportableType resolveType(DartType type) {
    return ImportableType(
      name: type.element?.name ?? type.getDisplayString(withNullability: false),
      isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
      import: resolveImport(type.element),
      typeArguments: _resolveTypeArguments(type),
    );
  }
}
