import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route/annotations.dart';
import 'package:auto_route_generator/build_utils.dart';
import 'package:auto_route_generator/src/builders/auto_route_builder.dart';
import 'package:auto_route_generator/src/builders/build_step_primary_output.dart';
import 'package:auto_route_generator/src/builders/cache_aware_builder.dart';
import 'package:auto_route_generator/src/code_builder/library_builder.dart';
import 'package:auto_route_generator/src/models/route_config.dart';
import 'package:auto_route_generator/src/models/router_config.dart';
import 'package:auto_route_generator/src/models/routes_list.dart';
import 'package:auto_route_generator/src/resolvers/router_config_resolver.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

const _kTypeChecker = TypeChecker.typeNamed(AutoRouterConfig, inPackage: 'auto_route');

/// Base class for `AutoRouterBuilder` and `AutoRouterModuleBuilder`
abstract class AutoRouterBuilderBase extends CacheAwareBuilder<RouterConfig> {
  /// Default constructor
  new({
    required super.generatedExtension,
    required super.allowSyntaxErrors,
    required super.annotationName,
    super.options,
  });

  @override
  bool get cacheEnabled => options?.config['enable_cached_builds'] == true;

  @override
  Future<RouterConfig?> loadFromCache(BuildStep buildStep, int stepHash) async {
    final cachedRouterFile = _buildRouterFile(buildStep, toCache: true);
    if (cachedRouterFile.existsSync()) {
      final json = jsonDecode(await cachedRouterFile.readAsString()) as Map<String, dynamic>;
      if (json['cacheHash'] == stepHash) {
        return RouterConfig.fromJson(json);
      }
    }
    return null;
  }

  @override
  int calculateUpdatableHash(CompilationUnit unit) {
    var calculatedHash = 0;
    for (final clazz in unit.declarations.whereType<ClassDeclaration>()) {
      final routerAnnotation = clazz.metadata.where((e) => e.name.name == annotationName).firstOrNull;
      if (routerAnnotation == null) continue;
      final partDirectives = unit.directives.whereType<PartDirective>().fold<int>(
        0,
        (acc, a) => acc ^ a.toSource().hashCode,
      );
      calculatedHash =
          calculatedHash ^ clazz.namePart.toString().hashCode ^ routerAnnotation.toSource().hashCode ^ partDirectives;
    }
    return calculatedHash;
  }

  bool _hasPartDirective(ClassElement clazz, AssetId output) {
    final uriIncludes = clazz.library.firstFragment.partIncludes.map((e) => e.uri);
    return uriIncludes.whereType<DirectiveUriWithSource>().any((e) => e.source.fullName.endsWith(output.path));
  }

  @override
  Future<String> onGenerateContent(BuildStep buildStep, RouterConfig item) async {
    final generateForDir = item.generateForDir;
    final generatedResults = <RoutesList>[];
    final routes = <RouteConfig>[];
    await for (final asset in buildStep.findAssets(Glob('**.route.json'))) {
      final jsonRes = jsonDecode(await buildStep.readAsString(asset));
      final generatedRes = RoutesList.fromJson(jsonRes as Map<String, dynamic>);
      generatedResults.add(generatedRes);
      if (generateForDir.any(asset.path.startsWith)) {
        routes.addAll(generatedRes.routes);
      }
    }
    try {
      _writeRouterFile(buildStep, item);
      if (cacheEnabled) {
        _writeRouterFile(buildStep, item, toCache: true);
        if (!routesCacheFile.existsSync()) {
          routesCacheFile.createSync(recursive: true);
        }
        routesCacheFile.writeAsStringSync(jsonEncode(generatedResults));
      }
      // A cache that can't be written only costs the next build its speed, so
      // any failure is reported and the build goes on.
    } on Object catch (e) {
      log.warning('Could not write config routerCache', e);
    }

    return '$_kHeader\n${generateLibrary(item, routes: routes..sort((a, b) => a.className.compareTo(b.className)), ignoreForFile: ignoreForFile, outputPath: buildStep.primaryOutput.path)}';
  }

  @override
  Future<RouterConfig?> onResolve(LibraryReader library, BuildStep buildStep, int stepHash) async {
    final annotatedElements = library.annotatedWith(_kTypeChecker);
    final annotated = annotatedElements.firstOrNull;
    if (annotated == null) return null;
    final element = annotated.element;
    final annotation = annotated.annotation;

    throwIf(element is! ClassElement, '${element.displayName} is not a class element', element: element);
    final clazz = element as ClassElement;

    final isPartOfLibrary = _hasPartDirective(clazz, buildStep.primaryOutput);

    final router = const RouterConfigResolver().resolve(
      annotation,
      buildStep.inputId,
      clazz,
      isPartOfLibrary: isPartOfLibrary,
      cacheHash: stepHash,
    );

    return router;
  }

  void _writeRouterFile(BuildStep buildStep, RouterConfig router, {bool toCache = false}) {
    final routerFile = _buildRouterFile(buildStep, toCache: toCache);
    if (!routerFile.existsSync()) {
      routerFile.createSync(recursive: true);
    }
    routerFile.writeAsStringSync(jsonEncode(router.toJson()));
  }

  File _buildRouterFile(BuildStep buildStep, {bool toCache = false}) {
    final path = [
      '.dart_tool/build',
      if (toCache) 'cache' else 'generated',
      buildStep.inputId.package,
      buildStep.inputId.changeExtension('.router_config.json').path,
    ].join('/');
    return File(path);
  }
}

const _kHeader = '''
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************
''';
