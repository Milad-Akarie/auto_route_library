import 'package:analyzer/dart/element/element.dart';

// holds constructor parameter info to be used
// in generating route parameters.
class RouteParameter {
  String type;
  String name;
  bool isPositional;
  String defaultValueCode;

  RouteParameter.fromParameterElement(ParameterElement parameterElement) {
    type = parameterElement.type.toString();
    name = parameterElement.name;
    isPositional = parameterElement.isPositional;
    defaultValueCode = parameterElement.defaultValueCode;
  }

  RouteParameter.fromJson(Map json) {
    type = json['type'];
    name = json['name'];
    isPositional = json['isPositional'];
    defaultValueCode = json['defaultValueCode'];
  }

  Map<String, dynamic> toJson() => {
        "type": type,
        "name": name,
        "isPositional": isPositional,
        "defaultValueCode": defaultValueCode,
      };
}
