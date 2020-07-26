import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:path/path.dart' as p;

class ImportResolver {
  final List<LibraryElement> libs;
  final Uri targetFile;

  ImportResolver(this.libs, this.targetFile);

  String resolve(Element element) {
    // return early if source is null or element is a core type
    if (element?.source == null || _isCoreDartType(element)) {
      return null;
    }

    for (var lib in libs) {
      if (lib.source != null && !_isCoreDartType(lib) && lib.exportNamespace.definedNames.keys.contains(element.name)) {
        return targetFile == null ? lib.source.uri.toString() : _relative(lib.source.uri, targetFile);
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

  Set<String> resolveAll(DartType type) {
    final imports = <String>{};
    imports.add(resolve(type.element));
    imports.addAll(_checkForParameterizedTypes(type));
    return imports..removeWhere((element) => element == null);
  }

  Set<String> _checkForParameterizedTypes(DartType typeToCheck) {
    final imports = <String>{};
    if (typeToCheck is ParameterizedType) {
      for (DartType type in typeToCheck.typeArguments) {
        imports.add(resolve(type.element));
        imports.addAll(_checkForParameterizedTypes(type));
      }
    }
    return imports;
  }
}
