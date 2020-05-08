import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
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

    // import type
    await _addImport(paramType);

    paramConfig.imports = imports;
    return paramConfig;
  }

  Future<void> _checkForParameterizedTypes(DartType paramType) async {
    //handle Function< G extends TypeA >( G item ) , when type is G , import TypeA source
    if (paramType is TypeParameterType) {
      await _addImport(paramType.bound);
    }
    if (paramType is ParameterizedType) {
      for (DartType type in paramType.typeArguments) {
        await _checkForParameterizedTypes(type);
        await _checkForFunctionArgumentTypes(type);
        if (type.element.source != null) {
          await _addImport(type);
        }
      }
    }
    if (paramType is FunctionType) {
      for (TypeParameterElement type in paramType.typeFormals) {
        if(type.bound!=null)
        await _addImport(type.bound);
      }
    }
  }

  Future<void> _checkForFunctionArgumentTypes(DartType type) async {
    //import types inside functionTypes recursively
    if (type is FunctionType) {
      var allFunctionParamTypes = [
        ...type.normalParameterTypes,
        ...type.optionalParameterTypes,
        ...type.namedParameterTypes.values,
        type.returnType
      ];
      for (DartType paramType in allFunctionParamTypes) {
        await _addImport(paramType);
      }
    }
  }

  Future<void> _addImport(DartType type) async {
    await _checkForFunctionArgumentTypes(type);
    await _checkForParameterizedTypes(type);

    final import = await _resolveLibImport(type.element);
    if (import != null) {
      imports.add(import);
    }
  }

  Future<String> _resolveLibImport(Element element) async {
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
