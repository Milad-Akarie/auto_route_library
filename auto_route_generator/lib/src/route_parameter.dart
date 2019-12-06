import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

// holds constructor parameter info to be used
// in generating route parameters.
class RouteParameter {
  String type;
  String name;
  bool isPositional;
  String defaultValueCode;
  List<String> imports = [];

  RouteParameter.fromParameterElement(ParameterElement parameterElement) {
    final paramType = parameterElement.type;
    type = paramType.toString();
    name = parameterElement.name;
    isPositional = parameterElement.isPositional;
    defaultValueCode = parameterElement.defaultValueCode;

    _addImport(paramType.element.source.uri);

    // import generic types
    if (paramType is ParameterizedType) {
      paramType.typeArguments.forEach((type) {
        if (type.element.source != null) _addImport(type.element.source.uri);
      });
    }
  }

  void _addImport(Uri uri) {
    if (uri == null) return;
    final path = uri.toString();

    // we don't need to import core dart types
    // or core flutter types
    if (!path.startsWith("dart:core/") &&
        !path.startsWith("package:flutter/")) {
      imports.add("'$path'");
    }
  }

  Iterable<DartType> getGenericTypes(DartType type) {
    return type is ParameterizedType ? type.typeArguments : const [];
  }

  RouteParameter.fromJson(Map json) {
    type = json['type'];
    name = json['name'];
    isPositional = json['isPositional'];
    defaultValueCode = json['defaultValueCode'];
    if (json['imports'] != null) imports = json['imports'].cast<String>();
  }

  Map<String, dynamic> toJson() => {
        "type": type,
        "name": name,
        "isPositional": isPositional,
        "defaultValueCode": defaultValueCode,
        if (imports != null) "imports": imports,
      };
}
