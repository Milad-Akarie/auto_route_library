import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:glob/glob.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route_generator/auto_router_generator.dart';
import 'package:auto_route_generator/src/code_builder/library_builder.dart';
import 'package:auto_route_generator/src/models/route_config.dart';
import 'package:auto_route_generator/src/models/router_config.dart';
import 'package:auto_route_generator/src/resolvers/type_resolver.dart';
import 'package:build/build.dart';
import 'package:glob/list_local_fs.dart';
import 'package:merging_builder_svb/merging_builder_svb.dart';
import 'package:source_gen/source_gen.dart';
import 'package:auto_route/annotations.dart';

Builder autoRouterBuilder(BuilderOptions options) {
  // gr stands for generated router.
  return LibraryBuilder(
    AutoRouterGenerator(),
    generatedExtension: '.gr.json',
    formatOutput: (generated) => generated.replaceAll(RegExp(r'//.*|\s'), ''),
  );
}

Builder autoRouteBuilder(BuilderOptions options) {
  BuilderOptions defaultOptions = BuilderOptions({
    'input_files': 'lib/**.dart',
    'output_file': 'lib/router.dart',
    'header': '',
    'footer': '',
    'sort_assets': false,
  });

  // Apply user set options.
  options = defaultOptions.overrideWith(options);
  return MergingBuilder<RouteConfig, LibDir>(
    generator: AutoRouteGenerator(),
    inputFiles: options.config['input_files'],
    outputFile: options.config['output_file'],
    header: options.config['header'],
    footer: options.config['footer'],
    sortAssets: options.config['sort_assets'],
  );
}

class AutoRouteGenerator extends MergingGenerator<RouteConfig, RoutePage> {

  @override
  FutureOr<String> generateMergedContent(Stream<RouteConfig> stream) async {
    final routers = await Glob("**.gr.json").list(root: './.dart_tool/build/generated/').toList();
    assert(routers.isNotEmpty);
    final fileContent = await File(routers.first.path).readAsString();
    final router = RouterConfig.fromJson(jsonDecode(fileContent));
    final routes = await stream.toList();
    // return '// ${routes.map((e) => e.pathName)}';
    return generateLibrary(router, routes: routes);
  }

  @override
  Stream<RouteConfig> generateStream(LibraryReader library, BuildStep buildStep) async* {
    final libs = await buildStep.resolver.libraries.toList();
    final resolver = TypeResolver(libs, null);
    for (final annotatedElement in library.annotatedWith(typeChecker)) {
      yield generateStreamItemForAnnotatedElement(
        annotatedElement.element,
        annotatedElement.annotation,
        buildStep,
      );
    }
  }

  @override
  RouteConfig generateStreamItemForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    return RouteConfig(
      pathName: 'pathName',
      className: element.getDisplayString(withNullability: false),
    );
  }
}
