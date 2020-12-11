import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route/annotations.dart';
import 'package:auto_route_generator/import_resolver.dart';
import 'package:auto_route_generator/route_config_resolver.dart';
import 'package:auto_route_generator/router_class_generator.dart';
import 'package:auto_route_generator/src/code_builder/library_builder.dart';
import 'package:auto_route_generator/utils.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

class AutoRouteGenerator extends GeneratorForAnnotation<AutoRouterAnnotation> {
  @override
  dynamic generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    // throw if annotation is used for a none class element
    throwIf(
      element is! ClassElement,
      '${element.name} is not a class element',
      element: element,
    );

    var libs = await buildStep.resolver.libraries.toList();

    var targetFileUri;
    if (annotation.peek('preferRelativeImports')?.boolValue != false) {
      targetFileUri = element.source.uri;
    }
    var importResolver = TypeResolver(libs, targetFileUri);

    var routerResolver = RouterConfigResolver(importResolver);
    final routerConfig = routerResolver.resolve(annotation, element);
    if (routerConfig.usesLegacyGenerator) {
      return RouterClassGenerator(routerConfig).generate();
    } else {
      return generateLibrary(routerConfig);
    }
  }
}
