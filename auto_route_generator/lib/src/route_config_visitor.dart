import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:auto_route_generator/route_config_visitor.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

// extracts route configs from a build step's element and annotation
class RouteClassVisitor extends SimpleElementVisitor {
  final AssetId inputId;
  final ConstantReader annotation;
  final routeConfig = RouteConfig();

  RouteClassVisitor(this.inputId, this.annotation) {
    final path = inputId.path;
    final package = inputId.package;
    routeConfig.import = "'package:$package/${path.replaceFirst('lib/', '')}'";

    if (annotation.peek("name") != null) routeConfig.name = annotation.peek("name").stringValue;

    if (annotation.peek("initial") != null) routeConfig.initial = annotation.peek("initial").boolValue;

    if (annotation.peek("fullscreenDialog") != null)
      routeConfig.fullscreenDialog = annotation.peek("fullscreenDialog").boolValue;

    if (annotation.peek("maintainState") != null)
      routeConfig.maintainState = annotation.peek("maintainState").boolValue;

    if (annotation.peek("durationInMilliseconds") != null) {
      routeConfig.durationInMilliseconds = annotation.peek("durationInMilliseconds").intValue;
    }

    if (annotation.peek("transitionBuilder") != null) {
      final function = annotation.peek("transitionBuilder").objectValue.toFunctionValue();
      final import = "'package:${function.source.uri.path.replaceFirst('lib/', '')}'";

      final displayName = function.displayName.replaceFirst(RegExp("^_"), "");
      final functionName = (function.isStatic && function.enclosingElement?.displayName != null)
          ? "${function.enclosingElement.displayName}.$displayName"
          : displayName;
      routeConfig.transitionBuilder = CustomTransitionBuilder(functionName, import);
    }
  }

  @override
  visitClassElement(ClassElement element) {
    routeConfig.className = element.displayName;
    final unnamedConstructor = element.unnamedConstructor;
    if (unnamedConstructor != null && unnamedConstructor.parameters != null) {
      routeConfig.parameters =
          unnamedConstructor.parameters.map((param) => RouteParameter.fromParameterElement(param)).toList();
    }
  }
}
