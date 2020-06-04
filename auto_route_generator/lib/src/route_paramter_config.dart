import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:auto_route/auto_route_annotations.dart';
import 'package:auto_route_generator/utils.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

final pathParamChecker = TypeChecker.fromRuntime(PathParam);
final queryParamChecker = TypeChecker.fromRuntime(QueryParam);

// holds constructor parameter info to be used
// in generating route parameters.
class RouteParamConfig {
  String type;
  String name;
  String _paramName;
  bool isPositional;
  bool isRequired;
  bool isPathParameter;
  bool isQueryParam;
  String defaultValueCode;
  Set<String> imports = {};

  String get getterName {
    switch (type) {
      case 'String':
        return 'stringValue';
      case 'int':
        return 'intValue';
      case 'double':
        return 'doubleValue';
      case 'num':
        return 'numValue';
      case 'bool':
        return 'boolValue';
      default:
        return 'value';
    }
  }

  String get paramName => _paramName ?? name;
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

    paramConfig.isPathParameter = pathParamChecker.hasAnnotationOfExact(parameterElement);
    if (paramConfig.isPathParameter) {
      paramConfig._paramName = pathParamChecker.firstAnnotationOf(parameterElement).getField('name')?.toStringValue();
    }

    paramConfig.isQueryParam = queryParamChecker.hasAnnotationOfExact(parameterElement);
    if (paramConfig.isQueryParam) {
      paramConfig._paramName = queryParamChecker.firstAnnotationOf(parameterElement).getField('name')?.toStringValue();
    }

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
