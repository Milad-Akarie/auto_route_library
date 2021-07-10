import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'annotation.dart';
import 'src/code_builder/library_builder.dart';
import 'src/resolvers/router_config_resolver.dart';
import 'src/resolvers/type_resolver.dart';
import 'utils.dart';

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

    Uri? targetFileUri;
    if (annotation.peek('preferRelativeImports')?.boolValue != false) {
      targetFileUri = element.source?.uri;
    }
    var importResolver = TypeResolver(libs, targetFileUri);

    var routerResolver = RouterConfigResolver(importResolver);
    final routerConfig =
        routerResolver.resolve(annotation, element as ClassElement);

    return generateLibrary(routerConfig);
  }
}
