import 'dart:async';
import 'dart:convert';
import 'package:auto_route_generator/src/models/route_config.dart';
import 'package:auto_route_generator/src/resolvers/route_config_resolver.dart';
import 'package:auto_route_generator/src/resolvers/type_resolver.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:auto_route/annotations.dart';

const _typeChecker = TypeChecker.fromRuntime(RoutePage);

class AutoRouteGenerator extends Generator {
  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    final routeResolver = RouteConfigResolver(
      TypeResolver(await buildStep.resolver.libraries.toList()),
    );
    final routes = <RouteConfig>[];
    for (var annotatedElement in library.annotatedWith(_typeChecker)) {
      final route = routeResolver.resolve(
        annotatedElement.element,
        annotatedElement.annotation,
      );
      routes.add(route);
    }
    return routes.isEmpty ? '' : jsonEncode(routes);
  }
}
