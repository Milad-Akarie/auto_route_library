import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route/router.dart';
import 'package:auto_route_annotation/src/router_class_generator.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'route_builder_config.dart';

class RouteGenerator extends GeneratorForAnnotation<AutoRouteApp> {
  final List<RouteConfig> collectedRoutes;
  RouteGenerator(this.collectedRoutes);

  @override
  generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) {
    final outputFile = AssetId(buildStep.inputId.package, 'lib/main.router.dart');
//    return buildStep.writeAsString(outputFile, "// outupe");
    print("--------------- RouteGeneerator buidling");
    return RouterClassGenerator(collectedRoutes).generate();
  }
}
