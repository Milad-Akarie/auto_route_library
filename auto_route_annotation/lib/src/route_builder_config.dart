import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

class RouteConfigBuilder {
  final LibraryReader library;
  final AssetId inputId;
  final AnnotatedElement annotatedElement;

  RouteConfigBuilder({this.library, this.inputId, this.annotatedElement});

  RouteConfig build() {
    final buildConfig = RouteConfig();
    final className = annotatedElement.element.displayName;
    buildConfig.className = className;

    final path = inputId.path;
    final package = inputId.package;
    buildConfig.import = "import 'package:$package/${path.replaceFirst('lib/', '')}';";

    final ClassElement classElement = library.findType(className);
    buildConfig.parameters = classElement.unnamedConstructor.parameters;
    return buildConfig;
  }
}

class RouteConfig {
  String import;
  String className;
  List<ParameterElement> parameters;

  @override
  String toString() {
    return 'RouteConfig{import: $import, className: $className}';
  }

  RouteConfig();
}
