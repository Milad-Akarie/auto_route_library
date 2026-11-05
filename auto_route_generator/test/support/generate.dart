import 'dart:convert';

import 'package:auto_route_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';

import 'compile_check_builder.dart';
import 'generated_router.dart';

export 'generated_router.dart';

/// The package the test sources live in.
const _kTestPackage = 'app';

/// The router library [generateRouter] adds when the sources hold none.
const _kDefaultRouterSource = '''
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
    final readerWriter = TestReaderWriter(rootPackage: _kTestPackage);
    await readerWriter.testing.loadIsolateSources();
    _packages = readerWriter;
  }
  return _packages!;
}

/// Runs the route builder and then the router builder over [sources], the
/// way `build_runner` runs them in an app, and returns the generated router.
///
/// [sources] maps paths inside the `app` package (`lib/home_page.dart`) to
/// their content; a path in another package names it first, as in
/// `skeleton|lib/login_page.dart`. When none of them holds `router.dart`,
/// `kDefaultRouterSource` is added as `lib/router.dart`.
///
/// [routerOptions] go to the router builder alone. [outputPath] is where the
/// router builder writes, next to the router by default.
Future<GeneratedRouter> generateRouter(
  Map<String, String> sources, {
  Map<String, Object> routerOptions = const {},
  String routerPath = 'lib/router.dart',
  String? outputPath,
}) async {
  final packages = await _loadPackages();
  final readerWriter = TestReaderWriter(rootPackage: _kTestPackage);
  for (final id in packages.testing.assets) {
    readerWriter.testing.writeBytes(id, packages.testing.readBytes(id));
  }
  final assets = {
    for (final entry in sources.entries)
      entry.key.contains('|') ? entry.key : '$_kTestPackage|${entry.key}': entry.value,
    if (!sources.containsKey(routerPath)) '$_kTestPackage|$routerPath': _kDefaultRouterSource,
  };
  outputPath ??= routerPath.replaceFirst(RegExp(r'\.dart$'), '.gr.dart');
  final result = await testBuilders(
    [
      autoRouteBuilder(.empty),
      autoRouterBuilder(BuilderOptions(routerOptions)),
      CompileCheckBuilder(routerPath, outputPath),
    ],
    assets,
    rootPackage: _kTestPackage,
    readerWriter: readerWriter,
    flattenOutput: true,
  );
  final files = result.readerWriter.testing;
  final outputId = AssetId(_kTestPackage, outputPath);
  final checkId = AssetId(_kTestPackage, routerPath.replaceFirst(RegExp(r'\.dart$'), kCompileErrorsExtension));
  return GeneratedRouter(
    files.exists(outputId) ? files.readString(outputId) : null,
    result.errors.toList(),
    files.exists(checkId) ? const LineSplitter().convert(files.readString(checkId)) : const [],
  );
}
