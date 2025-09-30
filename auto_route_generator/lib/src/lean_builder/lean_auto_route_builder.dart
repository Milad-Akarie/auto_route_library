import 'dart:async';
import 'dart:convert';

import 'package:auto_route/annotations.dart';
import 'package:auto_route_generator/src/lean_builder/resolvers/lean_route_config_resolver.dart';
import 'package:auto_route_generator/src/lean_builder/resolvers/lean_type_resolver.dart';
import 'package:lean_builder/builder.dart';
import 'package:lean_builder/element.dart';

import '../models/route_config.dart';
import '../models/routes_list.dart';

/// Builder that generates route configuration files based on [RoutePage] annotations
///
/// This builder scans Dart source files for classes annotated with [RoutePage] and
/// generates corresponding route configuration data in JSON format. The generated
/// files are used by [LeanAutoRouterBuilder] to create the final router implementation.
@LeanBuilder(
  generateToCache: true,
  registerTypes: {RoutePage, PathParam, QueryParam, UrlFragment},
  applies: {'LeanAutoRouterBuilder'},
)
class LeanAutoRouteBuilder extends Builder {
  /// The file extensions that this builder will output
  ///
  /// Generates '.route.ln.json' files containing route configuration data
  @override
  Set<String> get outputExtensions => {'.route.ln.json'};

  /// Determines if the builder should process the given build candidate
  ///
  /// Returns true if the candidate is a Dart source file that contains
  /// top-level metadata and class declarations
  @override
  bool shouldBuildFor(BuildCandidate candidate) {
    return candidate.isDartSource && candidate.hasClasses && candidate.hasTopLevelMetadata;
  }

  /// Executes the build process for the given [buildStep]
  ///
  /// Identifies classes annotated with [RoutePage], resolves their route
  /// configurations, and generates JSON files containing the route data
  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final routes = <RouteConfig>[];
    final resolver = buildStep.resolver;
    final routeResolver = LeanRouteConfigResolver(buildStep.resolver, LeanTypeResolver(resolver));
    final library = resolver.resolveLibrary(buildStep.asset);
    final typeChecker = resolver.typeCheckerOf<RoutePage>();

    for (var annotatedElement in library.annotatedWithExact(typeChecker)) {
      final route = routeResolver.resolve(
        annotatedElement.element,
        annotatedElement.annotation.constant as ConstObject,
      );
      routes.add(route);
    }

    if (routes.isEmpty) return;

    final routeList = RoutesList(
      routes: routes,
      inputPath: buildStep.asset.shortUri.toString(),
      inputHash: 0,
    );
    await buildStep.writeAsString(jsonEncode(routeList.toJson()), extension: '.route.ln.json');
  }
}
