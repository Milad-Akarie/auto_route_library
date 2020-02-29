import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route/auto_route_annotations.dart';
import 'package:auto_route_generator/route_config_resolver.dart';
import 'package:auto_route_generator/router_class_generator.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

class AutoRouteGenerator extends GeneratorForAnnotation<AutoRouter> {
  @override
  dynamic generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    // return early if annotation is used for a none class element
    if (element is! ClassElement) return null;

    // ensure router config classes are prefixed with $
    // to use the stripped name for the generated class

    if (!element.displayName.startsWith(r'$')) {
      throw ('\n ------------ Class name must be prefixed with \$ ------------ \n');
    }
    final routerClassName = element.displayName.replaceFirst(r'$', '');

    final routerConfig = RouterConfig.fromAnnotation(annotation);

    final routes = <RouteConfig>[];
    for (FieldElement field in (element as ClassElement).fields) {
      final routeConfig = await RouterConfigResolver(
              routerConfig.globalRouteConfig, buildStep.resolver)
          .resolve(field);
      routes.add(routeConfig);
    }

    //  throw an exception if there's more than one class annotated with @initial
    if (routes.where((r) => r.initial != null && r.initial).length > 1) {
      throw ('\n ------------ There can be only one initial route per navigator ------------ \n');
    }

    //  throw an exception if there's more than one class annotated with @unknownRoute
    if (routes
            .where((r) => r.isUnknownRoute != null && r.isUnknownRoute)
            .length >
        1) {
      throw ('\n ------------ There can be only one unknown route per navigator ------------ \n');
    }
    return RouterClassGenerator(routerClassName, routes, routerConfig)
        .generate();
  }
}
