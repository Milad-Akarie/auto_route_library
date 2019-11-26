import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route/auto_route_annotation.dart';
import 'package:auto_route_generator/router_class_generator.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

import 'route_config_visitor.dart';

class AutoRouteGenerator extends GeneratorForAnnotation<AutoRoute> {
  final _routerFile = File("lib/router.dart");
  final _routeConfigs = Map<String, RouteConfig>();
  final _formatter = DartFormatter();
  final _autoRouteFilesGlob = Glob("**.auto_route.json");

  AutoRouteGenerator() {
    _readExistingConfigFiles();
  }

  // read existingConfig files on builder initialization
  void _readExistingConfigFiles() {
    _autoRouteFilesGlob.listSync().forEach((input) {
      final file = File(input.path);
      final routePathKey = _stripPath(input.path);
      try {
        final jsonData = jsonDecode(file.readAsStringSync());
        _routeConfigs[routePathKey] = (RouteConfig.fromJson(jsonData));
      } catch (_) {
        // delete files with invalid json data
        file.delete();
      }
    });
  }

  @override
  generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) async {
    // return early if @AutoRoute is used for a none class element
    if (element is! ClassElement) return null;

    final routeClassVisitor = RouteClassVisitor(buildStep.inputId, annotation);
    routeClassVisitor.visitClassElement(element);
    final routeConfig = routeClassVisitor.routeConfig;

    final inputID = buildStep.inputId.changeExtension(".auto_route.json");
    final routePathKey = _stripPath(inputID.path);
    // add or replace new route config
    _routeConfigs[routePathKey] = routeConfig;
    return buildStep.writeAsString(inputID, jsonEncode(routeConfig.toJson())).then(_generateRouterCass);
  }

  // this function is called every time a buildStep is generated
  _generateRouterCass(_) {
    // check for deleted route files and remove them from the routeConfigs list
    final newList = _autoRouteFilesGlob.listSync().map((input) => _stripPath(input.path));
    _routeConfigs.removeWhere((k, _) => !newList.contains(k));

    // throw an exception if there's more than one class annotated with @InitialRoute()
    if (_routeConfigs.values.where((r) => r.initial != null).length > 1)
      throw ("\n ------------ There can be only one initial route ------------ \n");

    // format the output before it's written to the router.dart file.
    final formattedOutput = _formatter.format(RouterClassGenerator(_routeConfigs.values.toList()).generate());
    _routerFile.writeAsString(formattedOutput);
  }

  String _stripPath(String path) => path.substring(path.indexOf("lib/"), path.length);
}
