import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart' hide FunctionType;
import 'package:path/path.dart' as p;

class TypeResolver {
  final List<LibraryElement> libs;
  final Uri targetFile;

  TypeResolver(this.libs, this.targetFile);

  String resolveImport(Element element) {
    // return early if source is null or element is a core type
    if (element?.source == null || _isCoreDartType(element)) {
      return null;
    }

    for (var lib in libs) {
      if (lib.source != null && !_isCoreDartType(lib) && lib.exportNamespace.definedNames.values.contains(element)) {
        return targetFile == null
            ? lib.identifier
            : _relative(
                lib.source.uri,
                targetFile,
              );
      }
    }
    return null;
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
    return element.source.fullName == 'dart:core';
  }

  Iterable<ImportableType> _resolveTypeArguments(DartType typeToCheck) {
    final importableTypes = <ImportableType>[];
    if (typeToCheck is ParameterizedType) {
      for (DartType type in typeToCheck.typeArguments) {
        if (type.element is TypeParameterElement) {
          importableTypes.add(ImportableType(name: 'dynamic'));
        } else {
          importableTypes.add(ImportableType(
            name: type.element.name,
            import: resolveImport(type.element),
            typeArguments: _resolveTypeArguments(type),
          ));
        }
      }
    }
    return importableTypes;
  }

  ImportableType resolveImportableFunctionType(ExecutableElement function) {
    assert(function != null);
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

  // typedef OnPopped<T> = void Function(T result);
  ImportableType resolveType(DartType type) {
    return ImportableType(
      name: type.element?.name ?? type.getDisplayString(withNullability: false),
      import: resolveImport(type.element),
      typeArguments: _resolveTypeArguments(type),
    );
  }
}

class ImportableType {
  String import;
  String name;
  List<ImportableType> typeArguments;

  ImportableType({this.name, this.import, this.typeArguments});

  Set<String> get imports => fold.map((e) => e.import).toSet();

  List<ImportableType> get fold {
    var list = [this];
    typeArguments?.forEach((iType) {
      list.addAll(iType.fold);
    });
    return list;
  }

  String get identity => "$import#$name";

  String fullName({bool withTypeArgs = true}) {
    var typeArgs =
        withTypeArgs && (typeArguments?.isNotEmpty == true) ? "<${typeArguments.map((e) => e.name).join(',')}>" : '';
    return "$name$typeArgs";
  }

  String getDisplayName(Set<ImportableType> prefixedTypes, {bool withTypeArgs = true}) {
    return prefixedTypes?.lookup(this)?.fullName(withTypeArgs: withTypeArgs) ?? fullName(withTypeArgs: withTypeArgs);
  }

  Reference get simpleRefer => Reference(name, import);

  Reference get refer {
    if (typeArguments == null || typeArguments.isEmpty) {
      return Reference(name, import);
    } else {
      return TypeReference((b) => b
        ..symbol = name
        ..url = import
        ..types.addAll(typeArguments.map((e) => e.refer)));
    }
  }

  bool get isParametrized => typeArguments?.isNotEmpty == true;

  @override
  String toString() {
    return name;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImportableType && runtimeType == other.runtimeType && identity == other.identity;

  @override
  int get hashCode => import.hashCode ^ name.hashCode;

  ImportableType copyWith({
    String import,
    String name,
    List<ImportableType> typeArguments,
  }) {
    return new ImportableType(
      import: import ?? this.import,
      name: name ?? this.name,
      typeArguments: typeArguments ?? this.typeArguments,
    );
  }
}
