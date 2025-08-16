import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:auto_route/annotations.dart';
import 'package:auto_route_generator/build_utils.dart';
import 'package:auto_route_generator/src/builders/auto_route_builder.dart';
import 'package:auto_route_generator/src/builders/cache_aware_builder.dart';
import 'package:auto_route_generator/src/code_builder/library_builder.dart';
import 'package:auto_route_generator/src/models/route_config.dart';
import 'package:auto_route_generator/src/models/router_config.dart';
import 'package:auto_route_generator/src/models/routes_list.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

import '../resolvers/router_config_resolver.dart';

const _typeChecker = TypeChecker.typeNamed(AutoRouterConfig, inPackage: 'auto_route');

/// Base class for [AutoRouterBuilder] and [AutoRouterModuleBuilder]
abstract class AutoRouterBuilderBase extends CacheAwareBuilder<RouterConfig> {
  /// Default constructor
  AutoRouterBuilderBase({
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
    if (await cachedRouterFile.exists()) {
      final json = jsonDecode(await cachedRouterFile.readAsString());
      if (json['cacheHash'] == stepHash) {
        return RouterConfig.fromJson(json);
      }
    }
    return null;
  }

  @override
  int calculateUpdatableHash(CompilationUnit unit) {
    var calculatedHash = 0;
    for (final clazz in unit.declarations
        .whereType<ClassDeclaration>()
        .where((e) => e.metadata.any((e) => e.name.name == annotationName))) {
      final routerAnnotation = clazz.metadata.firstWhere((e) => e.name.name == annotationName);
      final partDirectives =
          unit.directives.whereType<PartDirective>().fold<int>(0, (acc, a) => acc ^ a.toSource().hashCode);
      calculatedHash =
          calculatedHash ^ clazz.name.toString().hashCode ^ routerAnnotation.toSource().hashCode ^ partDirectives;
    }
    return calculatedHash;
  }

  bool _hasPartDirective(ClassElement2 clazz) {
    final fileName = clazz.library2.uri.pathSegments.last;
    final part = fileName.replaceAll('.dart', generatedExtension);
    final uriIncludes = clazz.library2.firstFragment.partIncludes.map((e) => e.uri);
    return uriIncludes.whereType<DirectiveUriWithSource>().any(
          (e) => e.source.fullName.endsWith(part),
        );
  }

  @override
  Future<String> onGenerateContent(BuildStep buildStep, RouterConfig item) async {
    final generateForDir = item.generateForDir;
    final generatedResults = <RoutesList>[];
    final routes = <RouteConfig>[];
    await for (final asset in buildStep.findAssets(Glob("**.route.json"))) {
      final jsonRes = jsonDecode(await buildStep.readAsString(asset));
      final generatedRes = RoutesList.fromJson(jsonRes);
      generatedResults.add(generatedRes);
      if (generateForDir.any((dir) => asset.path.startsWith(dir))) {
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
        routesCacheFile.writeAsStringSync(
          jsonEncode(generatedResults),
        );
      }
    } catch (e) {
      print('Could not write config routerCache');
    }

    return '$_header\n${generateLibrary(
      item,
      routes: routes..sort((a, b) => a.className.compareTo(b.className)),
      ignoreForFile: ignoreForFile,
    )}';
  }

  @override
  Future<RouterConfig?> onResolve(LibraryReader library, BuildStep buildStep, int stepHash) async {
    final annotatedElements = library.annotatedWith(_typeChecker);
    if (annotatedElements.isEmpty) return null;
    final element = annotatedElements.first.element;
    final annotation = annotatedElements.first.annotation;

    throwIf(
      element is! ClassElement2,
      '${element.displayName} is not a class element',
      element: element,
    );
    final clazz = element as ClassElement2;

    final usesPartBuilder = _hasPartDirective(clazz);

    final router = RouterConfigResolver().resolve(
      annotation,
      buildStep.inputId,
      clazz,
      usesPartBuilder: usesPartBuilder,
      cacheHash: stepHash,
    );

    return router;
  }

  void _writeRouterFile(BuildStep buildStep, RouterConfig router, {bool toCache = false}) {
    final routerFile = _buildRouterFile(buildStep, toCache: toCache);
    if (!routerFile.existsSync()) {
      routerFile.createSync(recursive: true);
    }
    routerFile.writeAsStringSync(
      jsonEncode(router.toJson()),
    );
  }

  File _buildRouterFile(BuildStep buildStep, {bool toCache = false}) {
    final path = [
      '.dart_tool/build',
      toCache ? 'cache' : 'generated',
      buildStep.inputId.package,
      buildStep.inputId.changeExtension('.router_config.json').path
    ].join('/');
    return File(path);
  }
}

const _header = '''
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************
''';
