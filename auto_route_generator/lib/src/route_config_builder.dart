import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route/auto_route_annotation.dart';
import 'package:auto_route_generator/route_config_builder.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

// extracts route configs from a build step's annotation
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
    buildConfig.import = "'package:$package/${path.replaceFirst('lib/', '')}'";

    buildConfig.parameters = classElement.unnamedConstructor.parameters?.map((param) => RouteParameter.fromParameterElement(param))?.toList();

    if (annotation.peek("name") != null) buildConfig.name = annotation.peek("name").stringValue;
//    print(annotation.instanceOf(TypeChecker.fromRuntime(InitialRoute)));
    if (annotation.peek("initial") != null) buildConfig.initial = annotation.peek("initial").boolValue;

    if (annotation.peek("fullscreenDialog") != null) buildConfig.fullscreenDialog = annotation.peek("fullscreenDialog").boolValue;

    if (annotation.peek("maintainState") != null) buildConfig.maintainState = annotation.peek("maintainState").boolValue;

    if (annotation.peek("durationInMilliseconds") != null) {
      buildConfig.durationInMilliseconds = annotation.peek("durationInMilliseconds").intValue;
    }

    if (annotation.peek("transitionBuilder") != null) {
      final res = annotation.peek("transitionBuilder").objectValue.toFunctionValue();
      final import = "'package:${res.source.uri.path.replaceFirst('lib/', '')}'";

      final displayName = res.displayName.replaceFirst(RegExp("^_"), "");
      final functionName =
          (res.isStatic && res.enclosingElement?.displayName != null) ? "${res.enclosingElement.displayName}.$displayName" : displayName;
      buildConfig.transitionBuilder = CustomTransitionBuilder(functionName, import);
    }

    return buildConfig;
  }
}
