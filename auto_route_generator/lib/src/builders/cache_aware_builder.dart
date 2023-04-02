import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart';

final _formatter = DartFormatter(fixes: [StyleFix.singleCascadeStatements]);

abstract class CacheAwareBuilder<T> extends Builder {
  /// The [buildExtensions] configuration for `.dart`
  final String _generatedExtension;

  /// Whether to allow syntax errors in input libraries.
  final bool allowSyntaxErrors;

  final String annotationName;

  bool get cacheEnabled;

  @override
  final Map<String, List<String>> buildExtensions;
  final BuilderOptions? options;

  CacheAwareBuilder({
    String generatedExtension = '.g.dart',
    List<String> additionalOutputExtensions = const [],
    this.allowSyntaxErrors = false,
    required this.annotationName,
    this.options,
  })  : _generatedExtension = generatedExtension,
        buildExtensions = validatedBuildExtensionsFrom(
            options != null ? Map.of(options.config) : null, {
          '.dart': [
            generatedExtension,
            ...additionalOutputExtensions,
          ]
        }) {
    if (_generatedExtension.isEmpty || !_generatedExtension.startsWith('.')) {
      throw ArgumentError.value(
        _generatedExtension,
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
    if (!(await hasAnyTopLevelAnnotations(
        buildStep.inputId, buildStep, unit))) {
      return;
    }

    var cacheHash = 0;
    if (cacheEnabled) {
      cacheHash = calculateUpdatableHash(unit);
      final cached = await loadFromCache(buildStep, cacheHash);
      if (cached != null) {
        return _writeContent(buildStep, cached);
      }
    }

    final lib = await resolver.libraryFor(
      buildStep.inputId,
      allowSyntaxErrors: allowSyntaxErrors,
    );
    var generated = await onResolve(LibraryReader(lib), buildStep, cacheHash);
    if (generated == null) return null;
    return _writeContent(buildStep, generated);
  }

  Future<T?> loadFromCache(BuildStep buildStep, int stepHash);

  int calculateUpdatableHash(CompilationUnit unit);

  Future<String> onGenerateContent(BuildStep buildStep, T item);

  Future<T?> onResolve(
      LibraryReader library, BuildStep buildStep, int stepHash);

  String validateAndFormatDartCode(BuildStep buildStep, String generated) {
    try {
      return _formatter.format(generated);
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

  Future<void> _writeContent(BuildStep buildStep, generated) async {
    var output = await onGenerateContent(buildStep, generated);
    final outputId = buildStep.allowedOutputs.first;
    if (outputId.extension.endsWith('.dart')) {
      output = validateAndFormatDartCode(buildStep, output);
    }
    return buildStep.writeAsString(outputId, output);
  }

  @override
  String toString() =>
      'Generating $_generatedExtension: ${this.runtimeType.toString()}';

  Future<bool> hasAnyTopLevelAnnotations(AssetId input, BuildStep buildStep,
      [CompilationUnit? unit]) async {
    if (!await buildStep.canRead(input)) return false;
    final parsed = unit ?? await buildStep.resolver.compilationUnitFor(input);
    final partIds = <AssetId>[];
    for (var directive in parsed.directives) {
      if (directive.metadata.any((e) => e.name.name == annotationName))
        return true;
      if (directive is PartDirective) {
        partIds.add(
          AssetId.resolve(Uri.parse(directive.uri.stringValue!), from: input),
        );
      }
    }
    for (var declaration in parsed.declarations) {
      if (declaration.metadata.any((e) => e.name.name == annotationName))
        return true;
    }
    for (var partId in partIds) {
      if (await hasAnyTopLevelAnnotations(partId, buildStep)) {
        return true;
      }
    }
    return false;
  }
}

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
