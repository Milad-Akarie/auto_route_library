import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route/auto_route_annotations.dart';
import 'package:auto_route_generator/router_class_generator.dart';
import 'package:auto_route_generator/src/router_config.dart';
import 'package:auto_route_generator/src/router_config_visitor.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'route_config_visitor.dart';

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

    final visitor = RouterConfigVisitor();

    element.visitChildren(visitor);
    final routes = visitor.routeConfigs;
    //  throw an exception if there's more than one class annotated with @initial
    if (routes.where((r) => r.initial != null && r.initial).length > 1) {
      throw ('\n ------------ There can be only one initial route per navigator ------------ \n');
    }
    final routerConfig = RouterConfig.fromAnnotation(annotation);
    return RouterClassGenerator(routerClassName, routes, routerConfig)
        .generate();
  }
}
