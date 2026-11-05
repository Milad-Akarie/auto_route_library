import 'dart:convert';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:auto_route_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';

/// The package the test sources live in.
const kTestPackage = 'app';

/// The router library [generateRouter] adds when the sources hold none.
const kDefaultRouterSource = '''
import 'package:auto_route/auto_route.dart';

import 'router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [];
}
''';

TestReaderWriter? _packages;

/// Loads every package this isolate can see, once, so test sources can
/// import `package:flutter` and `package:auto_route`.
Future<TestReaderWriter> _loadPackages() async {
  if (_packages == null) {
    final readerWriter = TestReaderWriter(rootPackage: kTestPackage);
    await readerWriter.testing.loadIsolateSources();
    _packages = readerWriter;
  }
  return _packages!;
}

/// What one run of both builders produced.
class GeneratedRouter {
  /// Creates the result of one run.
  GeneratedRouter(this.source, this.errors, this.compileErrors);

  /// The generated `.gr.dart` source, or `null` when the build wrote none.
  final String? source;

  /// The errors the build reported.
  final List<String> errors;

  /// The analyzer errors in the router library and its generated part, so a
  /// test can check that the generated code compiles.
  final List<String> compileErrors;

  @override
  String toString() => 'build errors: $errors\ncompile errors: $compileErrors\n$source';
}

/// Runs the route builder and then the router builder over [sources], the
/// way `build_runner` runs them in an app, and returns the generated router.
///
/// [sources] maps paths inside the `app` package (`lib/home_page.dart`) to
/// their content; a path in another package names it first, as in
/// `skeleton|lib/login_page.dart`. When none of them holds `router.dart`,
/// [kDefaultRouterSource] is added as `lib/router.dart`.
///
/// [options] go to both builders, as `build.yaml` options of the package;
/// [routerOptions] go to the router builder alone. [outputPath] is where the
/// router builder writes, next to the router by default.
Future<GeneratedRouter> generateRouter(
  Map<String, String> sources, {
  Map<String, Object> options = const {},
  Map<String, Object> routerOptions = const {},
  String routerPath = 'lib/router.dart',
  String? outputPath,
}) async {
  final packages = await _loadPackages();
  final readerWriter = TestReaderWriter(rootPackage: kTestPackage);
  for (final id in packages.testing.assets) {
    readerWriter.testing.writeBytes(id, packages.testing.readBytes(id));
  }
  final assets = {
    for (final entry in sources.entries)
      entry.key.contains('|') ? entry.key : '$kTestPackage|${entry.key}': entry.value,
    if (!sources.containsKey(routerPath)) '$kTestPackage|$routerPath': kDefaultRouterSource,
  };
  outputPath ??= routerPath.replaceFirst(RegExp(r'\.dart$'), '.gr.dart');
  final result = await testBuilders(
    [
      autoRouteBuilder(BuilderOptions(options)),
      autoRouterBuilder(BuilderOptions({...options, ...routerOptions})),
      _CompileCheckBuilder(routerPath, outputPath),
    ],
    assets,
    rootPackage: kTestPackage,
    readerWriter: readerWriter,
    flattenOutput: true,
  );
  final files = result.readerWriter.testing;
  final outputId = AssetId(kTestPackage, outputPath);
  final checkId = AssetId(kTestPackage, routerPath.replaceFirst(RegExp(r'\.dart$'), _kCompileErrorsExtension));
  return GeneratedRouter(
    files.exists(outputId) ? files.readString(outputId) : null,
    result.errors.toList(),
    files.exists(checkId) ? const LineSplitter().convert(files.readString(checkId)) : const [],
  );
}

const _kCompileErrorsExtension = '.compile_errors.txt';

/// Resolves the router library once the router builder wrote its output, and
/// the output too when it is a library of its own, and writes the analyzer
/// errors in them, one per line.
class _CompileCheckBuilder implements Builder {
  _CompileCheckBuilder(this.routerPath, this.outputPath);
  final String routerPath;
  final String outputPath;

  @override
  Map<String, List<String>> get buildExtensions => const {
    '.dart': [_kCompileErrorsExtension],
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
          for (final e in result.diagnostics.where((e) => e.severity == .error)) {
            errors.add('${fragment.source.uri.pathSegments.last}: ${e.message}');
          }
        }
      }
    }
    await buildStep.writeAsString(buildStep.allowedOutputs.single, errors.join('\n'));
  }
}
