import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';

Future<Set<String>> resolveImports(Resolver resolver, DartType type) async {
  final imports = <String>{};
  imports.add(await _resolveLibImport(resolver, type.element));
  imports.addAll(await _checkForParameterizedTypes(resolver, type));
  return imports..removeWhere((element) => element == null);
}

Future<Set<String>> _checkForParameterizedTypes(
    Resolver resolver, DartType typeToCheck) async {
  final imports = <String>{};
  if (typeToCheck is ParameterizedType) {
    for (DartType type in typeToCheck.typeArguments) {
      imports.add(await _resolveLibImport(resolver, type.element));
      imports.addAll(await _checkForParameterizedTypes(resolver, type));
    }
  }
  return imports;
}

Future<String> _resolveLibImport(Resolver resolver, Element element) async {
  if (element?.source == null || isCoreDartType(element)) {
    return null;
  }
  //if element from a system library but not from dart:core
  if (element.source.isInSystemLibrary) {
    return getImport(element);
  }
  final assetId = await resolver.assetIdForElement(element);
  final lib = await resolver.findLibraryByName(assetId.package);
  if (lib != null) {
    return getImport(lib);
  } else {
    return getImport(element);
  }
}

// Checks if source is from dart:core library
bool isCoreDartType(Element element) {
  return element.source.isInSystemLibrary &&
      element.source.uri.path.startsWith('core/');
}

String getImport(Element element) {
  // return early if source is null
  final source = element.librarySource ?? element.source;
  if (source == null) {
    return null;
  }

  // we don't need to import core dart types
  // or core flutter types
  if (!isCoreDartType(element)) {
    final path = source.uri.toString();
    if (!path.startsWith('package:flutter/')) {
      return "'$path'";
    }
  }
  return null;
}
