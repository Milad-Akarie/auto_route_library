import 'dart:convert';
import 'dart:io';
import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route_generator/src/code_builder/library_builder.dart';
import 'package:auto_route_generator/src/models/route_config.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';
import 'src/resolvers/router_config_resolver.dart';
import 'utils.dart';
import 'package:auto_route/annotations.dart';

class AutoRouterGenerator extends GeneratorForAnnotation<AutoRouterConfig> {
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
    final clazz = element as ClassElement;
    final usesPartBuilder = _hasPartDirective(clazz);
    final router = RouterConfigResolver().resolve(
      annotation,
      buildStep.inputId,
      clazz,
      usesPartBuilder: usesPartBuilder,
    );

    final generateForDir = annotation
        .read('generateForDir')
        .listValue
        .map((e) => e.toStringValue());

    final routes = <RouteConfig>[];
    await for (final asset in buildStep.findAssets(Glob("${generateForDir.join(',')}/**.route.json"))) {
      final jsonList = jsonDecode(await buildStep.readAsString(asset));
      for(final json in jsonList as List<dynamic>){
        routes.add(RouteConfig.fromJson(json));
      }
    }


    try {
      final path = [buildStep.inputId.package,buildStep.inputId.changeExtension('.router_config.json').path].join('/');
      final file = File('.dart_tool/build/generated/$path');
      if (!file.existsSync()) {
        file.createSync(recursive: true);
      }
      file.writeAsStringSync(
        jsonEncode(router.toJson()),
      );
    } catch (e) {
      print('Could not write config file');
    }

    return generateLibrary(router, routes: routes);
  }

  bool _hasPartDirective(ClassElement clazz) {
    final fileName = clazz.source.uri.pathSegments.last;
    final part = fileName.replaceAll(
      '.dart',
      '.gr.dart',
    );
    return clazz.library.parts.any(
      (e) => e.toString().endsWith(part),
    );
  }
}
