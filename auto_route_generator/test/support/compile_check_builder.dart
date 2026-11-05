import 'package:analyzer/dart/analysis/results.dart';
import 'package:build/build.dart';

/// The extension of the file [CompileCheckBuilder] writes its errors to.
const kCompileErrorsExtension = '.compile_errors.txt';

/// Resolves the router library once the router builder wrote its output, and
/// the output too when it is a library of its own, and writes the analyzer
/// errors in them, one per line.
class CompileCheckBuilder implements Builder {
  const new(this.routerPath, this.outputPath);
  final String routerPath;
  final String outputPath;

  @override
  Map<String, List<String>> get buildExtensions => const {
    '.dart': [kCompileErrorsExtension],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    if (buildStep.inputId.path != routerPath) return;
    final libraries = [buildStep.inputId];
    final outputId = AssetId(buildStep.inputId.package, outputPath);
    if (await buildStep.canRead(outputId) && await buildStep.resolver.isLibrary(outputId)) {
      libraries.add(outputId);
    }
    final errors = <String>[];
    for (final id in libraries) {
      final library = await buildStep.resolver.libraryFor(id);
      for (final fragment in library.fragments) {
        final result = await library.session.getErrors(fragment.source.fullName);
        if (result is ErrorsResult) {
          for (final e in result.diagnostics.where((diagnostic) => diagnostic.severity == .error)) {
            errors.add('${fragment.source.shortName}: ${e.message}');
          }
        }
      }
    }
    final [output] = buildStep.allowedOutputs.toList();
    await buildStep.writeAsString(output, errors.join('\n'));
  }
}
