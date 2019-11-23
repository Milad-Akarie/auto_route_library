import 'package:analyzer/dart/element/element.dart';

// holds constructor parameter info to be used
// in generating route parameters.
class RouteParameter {
  String type;
  String name;
  bool isPositional;
  String defaultValueCode;
  String import;

  RouteParameter.fromParameterElement(ParameterElement parameterElement) {
    type = parameterElement.type.toString();
    name = parameterElement.name;
    isPositional = parameterElement.isPositional;
    defaultValueCode = parameterElement.defaultValueCode;

    final path = parameterElement.type.element.source.uri.toString();
    // we don't need to import core types
    if (path != null && !path.startsWith("dart:core/"))
      import = "'$path'";

  }

  RouteParameter.fromJson(Map json) {
    type = json['type'];
    name = json['name'];
    isPositional = json['isPositional'];
    defaultValueCode = json['defaultValueCode'];
    import = json['import'];
  }

  Map<String, dynamic> toJson() => {
        "type": type,
        "name": name,
        "isPositional": isPositional,
        "defaultValueCode": defaultValueCode,
        if (import != null) "import": import,
      };
}
