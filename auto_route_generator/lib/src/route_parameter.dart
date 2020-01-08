import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:auto_route_generator/utils.dart';

// holds constructor parameter info to be used
// in generating route parameters.
class RouteParameter {
  String type;
  String name;
  bool isPositional;
  bool isRequired;
  String defaultValueCode;
  Set<String> imports = {};

  RouteParameter.fromParameterElement(ParameterElement parameterElement) {
    final paramType = parameterElement.type;
    type = paramType.toString();
    name = parameterElement.name;
    isPositional = parameterElement.isPositional;
    defaultValueCode = parameterElement.defaultValueCode;
    isRequired = parameterElement.hasRequired;

    // import type
    _addImport(paramType.element.source.uri);

    // import generic types recursively
    _checkForParameterizedTypes(paramType);
  }

  void _checkForParameterizedTypes(DartType paramType) {
    if (paramType is ParameterizedType) {
      paramType.typeArguments.forEach((type) {
        _checkForParameterizedTypes(type);
        if (type.element.source != null) {
          _addImport(type.element.source.uri);
        }
      });
    }
  }

  void _addImport(Uri uri) {
    final import = getImport(uri);
    if (import != null) {
      imports.add(import);
    }
  }
}
