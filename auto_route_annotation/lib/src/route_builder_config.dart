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

//    final ClassElement classElement = library.findType(className);
    print(className);

    //  final ClassElement transClass = library.findType("TransBuilder");
//    print(transClass.methods.toString());

    buildConfig.parameters = classElement.unnamedConstructor.parameters;

    if (annotation.peek("name") != null) buildConfig.name = annotation.peek("name").stringValue;

    if (annotation.peek("fullscreenDialog") != null)
      buildConfig.fullscreenDialog = annotation.peek("fullscreenDialog").boolValue;

    if (annotation.peek("maintainState") != null)
      buildConfig.maintainState = annotation.peek("maintainState").boolValue;

    return buildConfig;
  }
}

class RouteConfig {
  String name;
  bool fullscreenDialog;
  bool maintainState;
  String import;
  String className;
  List<ParameterElement> parameters;

  @override
  String toString() {
    return 'RouteConfig{className: $className}';
  }

  RouteConfig();
}
