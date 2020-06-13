import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route/auto_route_annotations.dart';
import 'package:auto_route_generator/route_config_resolver.dart';
import 'package:auto_route_generator/router_class_generator.dart';
import 'package:auto_route_generator/utils.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

const autoRouteChecker = TypeChecker.fromRuntime(AutoRoute);

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

//    throwIf(
//      autoRoutes.type.toString() != 'List<AutoRoute>' || !autoRoutes.isConst || !autoRoutes.isStatic,
//      'Routes list must be a static const List<AutoRoute>',
//      element: autoRoutes,
//    );
    var routerResolver = RouterConfigResolver(getResolver(buildStep));
    final routerConfig = await routerResolver.resolve(annotation, element);

    return RouterClassGenerator(routerConfig).generate();
  }

  Resolver getResolver(BuildStep buildStep) => buildStep.resolver;
}
