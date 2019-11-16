import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route/auto_route.dart';
import 'package:auto_route_annotation/src/router_class_generator.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart';

import 'route_builder_config.dart';

class AutoRouteGenerator extends GeneratorForAnnotation<AutoRoute> {
  final _routerFile = File("lib/router.dart");
  final _routerConfigFile = File("lib/routes.json");
  Map<String, dynamic> _routes;
  final _formatter = DartFormatter();

  @override
  generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) async {
    print(buildStep.inputId.path);


    final configBuilder = RouteConfigBuilder(classElement: element, inputId: buildStep.inputId, annotation: annotation);
    final routeConfig = configBuilder.build();

    if (_routes == null) {
      String existingConfig;
      if (await _routerConfigFile.exists()) existingConfig = await _routerConfigFile.readAsString();
      _routes = (existingConfig != null && existingConfig.isNotEmpty) ? jsonDecode(existingConfig) : Map();
    }

    _routes[routeConfig.className] = routeConfig.toJson();
    _routerConfigFile.writeAsString(jsonEncode(_routes));

    final routesConfig = _routes.values.map<RouteConfig>((v) => RouteConfig.fromJson(v)).toList();
    final formattedOutput = _formatter.format(RouterClassGenerator(routesConfig).generate());
    _routerFile.writeAsString(formattedOutput);
    return null;
  }
}
