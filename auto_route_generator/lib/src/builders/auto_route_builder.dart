import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:auto_route/annotations.dart';
import 'package:auto_route_generator/src/builders/cache_aware_builder.dart';
import 'package:auto_route_generator/src/models/route_config.dart';
import 'package:auto_route_generator/src/models/routes_list.dart';
import 'package:auto_route_generator/src/resolvers/route_config_resolver.dart';
import 'package:auto_route_generator/src/resolvers/type_resolver.dart';
import 'package:auto_route_generator/utils.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

const _typeChecker = TypeChecker.typeNamed(RoutePage, inPackage: 'auto_route');

/// Default location of the routes cache file
final routesCacheFile = File('.dart_tool/build/cache/auto_routes_cache.json');

final _cacheResource = Resource<Map<String, RoutesList>>(
  () async {
    final cachedRes = <String, RoutesList>{};
    final jsonRes = jsonDecode(await routesCacheFile.readAsString());
    for (final json in jsonRes as List<dynamic>) {
      final generated = RoutesList.fromJson(json);
      cachedRes[generated.inputPath] = generated;
    }

    return cachedRes;
  },
);

/// A [Builder] which generates json route files for annotated pages
class AutoRouteBuilder extends CacheAwareBuilder<RoutesList> {
  /// Default constructor
  AutoRouteBuilder({super.options})
      : super(
          generatedExtension: '.route.json',
          allowSyntaxErrors: true,
          annotationName: 'RoutePage',
        );

  @override
  bool get cacheEnabled => options?.config['enable_cached_builds'] == true;

  @override
  Future<RoutesList?> loadFromCache(BuildStep buildStep, int stepHash) async {
    Map<String, RoutesList> cachedRes = {};
    if (await routesCacheFile.exists()) {
      cachedRes = await buildStep.fetchResource(_cacheResource);
    }
    if (cachedRes.containsKey(buildStep.inputId.path)) {
      final cached = cachedRes[buildStep.inputId.path]!;
      if (cached.inputHash == stepHash) {
        return cached;
      }
    }
    return null;
  }

  @override
  int calculateUpdatableHash(CompilationUnit unit) {
    var calculatedHash = 0;
    for (final clazz in unit.declarations.where((e) => e.metadata.isNotEmpty)) {
      for (final child in clazz.childEntities.whereType<ClassMember>()) {
        if (child is ConstructorDeclaration || child is FieldDeclaration) {
          calculatedHash = calculatedHash ^ child.toSource().hashCode;
        }
        final routePageMeta = clazz.metadata.firstWhereOrNull((e) => e.name.name == annotationName);
        if (routePageMeta != null) {
          calculatedHash = calculatedHash ^ routePageMeta.toSource().hashCode;
        }
      }
    }
    return calculatedHash;
  }

  @override
  Future<String> onGenerateContent(BuildStep buildStep, RoutesList item) {
    return Future.value(jsonEncode(item));
  }

  @override
  Future<RoutesList?> onResolve(LibraryReader library, BuildStep buildStep, int stepHash) async {
    final routeResolver = RouteConfigResolver(TypeResolver(await buildStep.resolver.libraries.toList()));
    final routes = <RouteConfig>[];
    for (var annotatedElement in library.annotatedWith(_typeChecker)) {
      final route = routeResolver.resolve(
        annotatedElement.element,
        annotatedElement.annotation,
      );
      routes.add(route);
    }
    return routes.isEmpty
        ? null
        : RoutesList(
            routes: routes,
            inputPath: buildStep.inputId.path,
            inputHash: stepHash,
          );
  }
}
