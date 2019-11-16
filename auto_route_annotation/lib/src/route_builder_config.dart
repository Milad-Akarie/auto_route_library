import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

class RouteConfigBuilder {
  final ClassElement classElement;
  final AssetId inputId;
  final ConstantReader annotation;

  RouteConfigBuilder({this.classElement, this.inputId, this.annotation});

  RouteConfig build() {
    final buildConfig = RouteConfig();
    final className = classElement.displayName;
    buildConfig.className = className;

    final path = inputId.path;
    final package = inputId.package;
    buildConfig.import = "import 'package:$package/${path.replaceFirst('lib/', '')}';";

    buildConfig.parameters = classElement.unnamedConstructor.parameters?.map((param) => RouteParameter.fromParameterElement(param))?.toList();

    if (annotation.peek("name") != null) buildConfig.name = annotation.peek("name").stringValue;

    if (annotation.peek("fullscreenDialog") != null) buildConfig.fullscreenDialog = annotation.peek("fullscreenDialog").boolValue;

    if (annotation.peek("maintainState") != null) buildConfig.maintainState = annotation.peek("maintainState").boolValue;

    if (annotation.peek("durationInMilliseconds") != null) {
      buildConfig.durationInMilliseconds = annotation.peek("durationInMilliseconds").intValue;
    }

    if (annotation.peek("transitionBuilder") != null) {
      final res = annotation.peek("transitionBuilder").objectValue.toFunctionValue();
      final import = "import 'package:${res.source.uri.path.replaceFirst('lib/', '')}';";

      final functionName =
          (res.isStatic && res.enclosingElement?.displayName != null) ? "${res.enclosingElement.displayName}.${res.displayName}" : res.displayName;
      buildConfig.transitionBuilder = CustomBuilderFunction(functionName, import);
    }

    return buildConfig;
  }
}

class RouteConfig {
  String name;
  bool fullscreenDialog;
  bool maintainState;
  String import;
  String className;
  List<RouteParameter> parameters;
  CustomBuilderFunction transitionBuilder;
  int durationInMilliseconds;

  RouteConfig();

  Map<String, dynamic> toJson() => {
        "className": className,
        "import": import,
        if (name != null) "name": name,
        if (transitionBuilder != null) "transitionBuilder": transitionBuilder.toJson(),
        if (durationInMilliseconds != null) "durationInMilliseconds": durationInMilliseconds,
        if (fullscreenDialog != null) "fullscreenDialog": fullscreenDialog,
        if (maintainState != null) "maintainState": maintainState,
        if (parameters != null) "parameters": parameters.map((v) => v.toJson()).toList(),
      };

  RouteConfig.fromJson(Map json) {
    name = json['name'];
    className = json['className'];
    import = json['import'];
    fullscreenDialog = json['fullscreenDialog'];
    transitionBuilder = json["transitionBuilder"] != null ? CustomBuilderFunction.fromJson(json["transitionBuilder"]) : null;
    durationInMilliseconds = json["durationInMilliseconds"];
    maintainState = json['maintainState'];
    parameters = json['parameters']?.map<RouteParameter>((v) => RouteParameter.fromJson(v))?.toList();
  }
}

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

class CustomBuilderFunction {
  String name;
  String import;

  CustomBuilderFunction(this.name, this.import);

  CustomBuilderFunction.fromJson(Map json) {
    name = json['name'];
    import = json['import'];
  }

  Map<String, dynamic> toJson() => {
        "import": import,
        "name": name,
      };
}
