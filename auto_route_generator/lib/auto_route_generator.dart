import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route/auto_route_annotation.dart';
import 'package:auto_route_generator/router_class_generator.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

import 'route_config_builder.dart';


class AutoRouteGenerator extends GeneratorForAnnotation<AutoRoute> {
  final _routerFile = File("lib/router.dart");
  List<RouteConfig> _routeConfigs;
  final _formatter = DartFormatter();
  final _autoRouteFilesGlob = Glob("**.auto_route.json");


  @override
  generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) async {
    // return early if @AutoRoute is used for a none class element
    if (element is! ClassElement) return null;

    // generate route config
    final configBuilder = RouteConfigBuilder(classElement: element, inputId: buildStep.inputId, annotation: annotation);
    final routeConfig = configBuilder.build();

    return buildStep
        .writeAsString(buildStep.inputId.changeExtension(".auto_route.json"), '${jsonEncode(routeConfig.toJson())}')
        .then(_generateRouterCass);
  }

  FutureOr _generateRouterCass(_) {
    _routeConfigs = List<RouteConfig>();

    _autoRouteFilesGlob.listSync().forEach((input) {
      final file = File(input.path);
      _routeConfigs.add(RouteConfig.fromJson(jsonDecode(file.readAsStringSync())));
    });

    if (_routeConfigs.where((r) => r.initial != null && r.initial).length > 1)
      throw ("------------ There can be only one initial route! ------------");

    final formattedOutput = _formatter.format(RouterClassGenerator(_routeConfigs).generate());
    _routerFile.writeAsStringSync(formattedOutput);
  }
}
