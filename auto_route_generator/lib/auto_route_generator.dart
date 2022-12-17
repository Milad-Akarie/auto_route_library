import 'dart:convert';
import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route_generator/src/resolvers/route_config_resolver.dart';
import 'package:auto_route_generator/src/resolvers/type_resolver.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:auto_route/annotations.dart';


class AutoRouteGenerator extends GeneratorForAnnotation<RoutePage> {
  @override
  dynamic generateForAnnotatedElement(
      Element element,
      ConstantReader annotation,
      BuildStep buildStep,
      ) async {
    final route = RouteConfigResolver(
      TypeResolver(await buildStep.resolver.libraries.toList()),
    ).resolve(element, annotation);
    return jsonEncode(route.toJson());
  }
}
