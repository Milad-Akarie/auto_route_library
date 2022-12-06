import 'dart:async';
import 'package:auto_route_generator/src/code_builder/library_builder.dart';
import 'package:auto_route_generator/src/models/route_config.dart';
import 'package:auto_route_generator/src/models/router_config.dart';
import 'package:auto_route_generator/src/resolvers/route_config_resolver.dart';
import 'package:auto_route/annotations.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route_generator/src/resolvers/type_resolver.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

class AutoRouteGenerator extends GeneratorForAnnotation<RoutePage> {
  FutureOr<void> generateMergedContent(
    Stream<RouteConfig> stream,
    BuildStep buildStep,
    RouterConfig router,
    AssetId outputAsset,
  ) async {
    final routes = await stream.toList();
    return buildStep.writeAsString(
      outputAsset,
      generateLibrary(router, routes: routes),
    );
  }

  Stream<RouteConfig> generateStream(LibraryReader library, BuildStep buildStep, RouterConfig router) async* {
    final libs = await buildStep.resolver.libraries.toList();
    final resolver = TypeResolver(libs, null);
    for (final annotatedElement in library.annotatedWith(typeChecker)) {
      yield generateStreamItemForAnnotatedElement(
        annotatedElement.element,
        annotatedElement.annotation,
        buildStep,
        router,
        resolver,
      );
    }
  }

  RouteConfig generateStreamItemForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
    RouterConfig router,
    TypeResolver resolver,
  ) {
    return RouteConfigResolver(router, resolver).resolve(element, annotation);
  }

  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    return '';
  }
}
