import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route/auto_route.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'route_builder_config.dart';

class RouteCollector extends GeneratorForAnnotation<AutoRoute> {
  final List<RouteConfig> collectedRoutes;

  RouteCollector(this.collectedRoutes) {
    print("--------------Router Collecter construct");
  }

  @override
  generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) async {
    final RouteConfigBuilder configBuilder =
        RouteConfigBuilder(classElement: element, inputId: buildStep.inputId, annotation: annotation);
    collectedRoutes.add(configBuilder.build());

//    return "// ${element.name}";
//
//    final outputFile = AssetId(buildStep.inputId.package, 'lib/app.router.dart');
//
//    return buildStep.writeAsString(outputFile, "//generated}");
  }
}
