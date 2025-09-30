import 'dart:async';
import 'dart:convert';

import 'package:auto_route/annotations.dart';
import 'package:auto_route_generator/src/code_builder/library_builder.dart';
import 'package:auto_route_generator/src/lean_builder/resolvers/lean_router_config_resolver.dart';
import 'package:auto_route_generator/src/models/route_config.dart';
import 'package:auto_route_generator/src/models/router_config.dart';
import 'package:auto_route_generator/src/models/routes_list.dart';
import 'package:lean_builder/builder.dart';
import 'package:lean_builder/element.dart';

import 'build_utils.dart';

const _configFilesDirectory = '.dart_tool/lean_build/generated';

/// Base class for [AutoRouterBuilder] and [AutoRouterModuleBuilder]
@LeanBuilder(registerTypes: {AutoRouterConfig})
class LeanAutoRouterBuilder extends Builder {
  /// Options provided to the builder from build.yaml
  final BuilderOptions? options;

  /// Creates a new [LeanAutoRouterBuilder] with the specified [options]
  LeanAutoRouterBuilder(this.options);

  /// The file extensions that this builder will output
  @override
  Set<String> get outputExtensions => {'.gr.dart'};

  /// Determines if the builder should process the given build candidate
  ///
  /// Returns true if the candidate is a Dart source file that contains
  /// top-level metadata and class declarations
  @override
  bool shouldBuildFor(BuildCandidate candidate) {
    return candidate.isDartSource && candidate.hasTopLevelMetadata && candidate.hasClasses;
  }

  /// Executes the build process for the given [buildStep]
  ///
  /// Identifies classes annotated with [AutoRouterConfig], resolves the router
  /// configuration, and generates the corresponding code
  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final resolver = buildStep.resolver;
    final typeChecker = resolver.typeCheckerOf<AutoRouterConfig>();
    final library = resolver.resolveLibrary(buildStep.asset);
    final annotatedElements = library.annotatedWithExact(typeChecker);
    if (annotatedElements.isEmpty) return null;

    final element = annotatedElements.first.element;
    final annotation = annotatedElements.first.annotation;

    throwIf(
      element is! ClassElement,
      '${element.name} is not a class element',
      element: element,
    );
    final clazz = element as ClassElement;

    final usesPartBuilder = buildStep.hasValidPartDirectiveFor('.gr.dart');

    final router = LeanRouterConfigResolver().resolve(
      annotation.constant as ConstObject,
      buildStep.asset,
      clazz,
      usesPartBuilder: usesPartBuilder,
    );

    final content = await onGenerateContent(buildStep, router);
    await buildStep.writeAsString(content, extension: '.gr.dart');
  }

  /// Returns a set of strings to include in the 'ignore_for_file' directive
  ///
  /// These are taken from the builder options configuration
  Set<String> get _ignoreForFile => options?.config['ignore_for_file']?.cast<String>()?.toSet() ?? {};

  /// Generates the content for the router file based on the configuration and routes
  ///
  /// This method collects route configurations from *.route.ln.json files,
  /// filters them based on the specified directory patterns, and generates
  /// the router implementation
  Future<String> onGenerateContent(BuildStep buildStep, RouterConfig config) async {
    final generateForDir = config.generateForDir;
    final generatedResults = <RoutesList>[];
    final routes = <RouteConfig>[];
    final assets = buildStep.findAssets(
      PathMatcher.regex(r".route.ln.json$", dotAll: false),
      subDir: _configFilesDirectory,
    );
    for (final asset in assets) {
      final jsonRes = jsonDecode(asset.readAsStringSync());
      final generatedRes = RoutesList.fromJson(jsonRes);
      // the location anchor is the path to the root package
      final locationAnchor = '$_configFilesDirectory/${buildStep.resolver.fileResolver.rootPackage}/';
      generatedResults.add(generatedRes);
      final location = asset.uri.path.split(locationAnchor).lastOrNull ?? '';
      if (generateForDir.any((dir) => location.startsWith(dir))) {
        routes.addAll(generatedRes.routes);
      }
    }
    return '$_header\n${generateLibrary(
      config,
      routes: routes..sort((a, b) => a.className.compareTo(b.className)),
      ignoreForFile: _ignoreForFile,
    )}';
  }
}

const _header = '''
// GENERATED CODE - DO NOT MODIFY BY HAND
$dartFormatWidth

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************
''';
