import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart';

/// A comment configuring `dart_style` to use the default code width so no
/// configuration discovery is required.
const dartFormatWidth = '// dart format width=80';

/// A [Builder] which skips resolving cached files
abstract class CacheAwareBuilder<T> extends Builder {
  /// The [buildExtensions] configuration for `.dart`
  final String generatedExtension;

  /// Whether to allow syntax errors in input libraries.
  final bool allowSyntaxErrors;

  /// The name of the annotation to look for.
  final String annotationName;

  /// Whether to enable cache
  bool get cacheEnabled;

  String _defaultFormatOutput(LibraryLanguageVersion libVersion, String code) {
    code = '$dartFormatWidth\n$code';
    return DartFormatter(languageVersion: libVersion.effective, pageWidth: 80).format(code);
  }

  /// Custom ignore for file rules passed from the options
  Set<String> get ignoreForFile => options?.config['ignore_for_file']?.cast<String>()?.toSet() ?? {};

  @override
  final Map<String, List<String>> buildExtensions;

  /// The [BuilderOptions] for this builder
  final BuilderOptions? options;

  /// Default constructor
  CacheAwareBuilder({
    this.generatedExtension = '.g.dart',
    List<String> additionalOutputExtensions = const [],
    this.allowSyntaxErrors = false,
    required this.annotationName,
    this.options,
  }) : buildExtensions = validatedBuildExtensionsFrom(options != null ? Map.of(options.config) : null, {
          '.dart': [
            generatedExtension,
            ...additionalOutputExtensions,
          ]
        }) {
    if (generatedExtension.isEmpty || !generatedExtension.startsWith('.')) {
      throw ArgumentError.value(
        generatedExtension,
        'generatedExtension',
        'Extension must be in the format of .*',
      );
    }

    if (options != null && additionalOutputExtensions.isNotEmpty) {
      throw ArgumentError(
        'Either `options` or `additionalOutputExtensions` parameter '
        'can be given. Not both.',
      );
    }
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    final resolver = buildStep.resolver;
    if (!await resolver.isLibrary(buildStep.inputId)) return;
    var unit = await resolver.compilationUnitFor(
      buildStep.inputId,
      allowSyntaxErrors: allowSyntaxErrors,
    );
    if (!(await hasAnyTopLevelAnnotations(buildStep.inputId, buildStep, unit))) {
      return;
    }

    var cacheHash = 0;
    if (cacheEnabled) {
      cacheHash = calculateUpdatableHash(unit);
      final cached = await loadFromCache(buildStep, cacheHash);
      if (cached != null) {
        final lib = await buildStep.inputLibrary;
        return _writeContent(buildStep, lib.languageVersion, cached);
      }
    }

    final lib = await resolver.libraryFor(
      buildStep.inputId,
      allowSyntaxErrors: allowSyntaxErrors,
    );
    var generated = await onResolve(LibraryReader(lib), buildStep, cacheHash);
    if (generated == null) return;
    return _writeContent(buildStep, lib.languageVersion, generated);
  }

  /// Loads the cached content from the cache
  Future<T?> loadFromCache(BuildStep buildStep, int stepHash);

  /// Calculates a hash for the current compilation unit
  int calculateUpdatableHash(CompilationUnit unit);

  /// Generates the content for the current compilation unit
  Future<String> onGenerateContent(BuildStep buildStep, T item);

  /// Resolves the current compilation unit
  Future<T?> onResolve(LibraryReader library, BuildStep buildStep, int stepHash);

  /// Validates the generated content and prepares it for writing
  String validateAndFormatDartCode(BuildStep buildStep, LibraryLanguageVersion libVersion, String generated) {
    try {
      return _defaultFormatOutput(libVersion, generated);
    } catch (e, stack) {
      log.severe(
        '''
An error `${e.runtimeType}` occurred while formatting the generated source for
  `${buildStep.inputId.path}`
which was output to
  `${buildStep.allowedOutputs.first.path}`.
This may indicate an issue in the generator, the input source code, or in the
source formatter.''',
        e,
        stack,
      );
      return generated;
    }
  }

  Future<void> _writeContent(BuildStep buildStep, LibraryLanguageVersion libVersion, generated) async {
    var output = await onGenerateContent(buildStep, generated);
    final outputId = buildStep.allowedOutputs.first;
    if (outputId.extension.endsWith('.dart')) {
      output = validateAndFormatDartCode(buildStep, libVersion, output);
    }
    return buildStep.writeAsString(outputId, output);
  }

  @override
  String toString() => 'Generating $generatedExtension: ${runtimeType.toString()}';

  /// Checks if the current compilation unit has any top level annotations
  Future<bool> hasAnyTopLevelAnnotations(AssetId input, BuildStep buildStep, [CompilationUnit? unit]) async {
    if (!await buildStep.canRead(input)) return false;
    final parsed = unit ?? await buildStep.resolver.compilationUnitFor(input);
    final partIds = <AssetId>[];
    for (var directive in parsed.directives) {
      if (directive.metadata.any((e) => e.name.name == annotationName)) {
        return true;
      }
      if (directive is PartDirective) {
        partIds.add(
          AssetId.resolve(Uri.parse(directive.uri.stringValue!), from: input),
        );
      }
    }
    for (var declaration in parsed.declarations) {
      if (declaration.metadata.any((e) => e.name.name == annotationName)) {
        return true;
      }
    }
    for (var partId in partIds) {
      if (await hasAnyTopLevelAnnotations(partId, buildStep)) {
        return true;
      }
    }
    return false;
  }
}

/// Validates the build extensions
Map<String, List<String>> validatedBuildExtensionsFrom(
  Map<String, dynamic>? optionsMap,
  Map<String, List<String>> defaultExtensions,
) {
  final extensionsOption = optionsMap?.remove('build_extensions');
  if (extensionsOption == null) return defaultExtensions;

  throw ArgumentError(
    'Configured build_extensions should be a map from inputs to outputs.',
  );
}
