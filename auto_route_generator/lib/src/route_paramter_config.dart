import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:auto_route_generator/utils.dart';
import 'package:build/build.dart';

// holds constructor parameter info to be used
// in generating route parameters.
class RouteParamConfig {
  String type;
  String name;
  bool isPositional;
  bool isRequired;
  String defaultValueCode;
  Set<String> imports = {};
}

class RouteParameterResolver {
  final Resolver _resolver;
  final Set<String> imports = {};

  RouteParameterResolver(this._resolver);

  Future<RouteParamConfig> resolve(ParameterElement parameterElement) async {
    final paramConfig = RouteParamConfig();
    final paramType = parameterElement.type;
    paramConfig.type = paramType.getDisplayString();
    paramConfig.name = parameterElement.name;
    paramConfig.isPositional = parameterElement.isPositional;
    paramConfig.defaultValueCode = parameterElement.defaultValueCode;
    paramConfig.isRequired = parameterElement.hasRequired;

    print(paramType.runtimeType);
    // import type
    await _addImport(paramType.element);

    // import generic types recursively
    await _checkForParameterizedTypes(paramType);

    paramConfig.imports = imports;
    return paramConfig;
  }

  Future<void> _checkForParameterizedTypes(DartType paramType) async {
    if (paramType is ParameterizedType) {
      for (DartType type in paramType.typeArguments) {
        await _checkForParameterizedTypes(type);
        if (type.element.source != null) {
          await _addImport(type.element);
        }
      }
    }
  }

  Future<void> _addImport(Element element) async {
    final import = await _resolveLibImport(element);
    if (import != null) {
      imports.add(import);
    }
  }

  Future<String> _resolveLibImport(Element element) async {
    print(element.name);
    if (element?.source == null || isCoreDartType(element.source)) {
      return null;
    }
    //if element from a system library but not from dart:core
    if (element.source.isInSystemLibrary) {
      return getImport(element);
    }
    final assetId = await _resolver.assetIdForElement(element);
    final lib = await _resolver.findLibraryByName(assetId.package);
    if (lib != null) {
      return getImport(lib);
    } else {
      return getImport(element);
    }
  }
}
