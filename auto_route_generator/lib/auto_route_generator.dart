import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route/auto_route_annotations.dart';
import 'package:auto_route_generator/route_config_resolver.dart';
import 'package:auto_route_generator/router_class_generator.dart';
import 'package:auto_route_generator/utils.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

class AutoRouteGenerator extends GeneratorForAnnotation<AutoRouter> {
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

    // ensure router config classes are prefixed with $
    // to use the stripped name for the generated class
    throwIf(
      !element.displayName.startsWith(r'$'),
      'Class name must be prefixed with \$',
      element: element,
    );

    final routerClassName = element.displayName.replaceFirst(r'$', '');

    final routerConfig = RouterConfig.fromAnnotation(annotation);

    final routes = <RouteConfig>[];
    final routerResolver = RouterConfigResolver(
      routerConfig.globalRouteConfig,
      getResolver(buildStep),
    );

    for (FieldElement field in (element as ClassElement).fields) {
      final routeConfig = await routerResolver.resolve(field);
      routes.add(routeConfig);
    }

    //  throw an exception if there's more than one class annotated with @initial
    throwIf(
      routes.where((r) => r.initial == true).length > 1,
      'There can be only one initial route per router',
      element: element,
    );

    //  throw an exception if there's more than one class annotated with @unknownRoute
    throwIf(
      routes.where((r) => r.isUnknownRoute == true).length > 1,
      'There can be only one unknown route per router',
      element: element,
    );

    return RouterClassGenerator(
      routerClassName,
      routes,
      routerConfig,
    ).generate();
  }

  Resolver getResolver(BuildStep buildStep) => buildStep.resolver;
}
