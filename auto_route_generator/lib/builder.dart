import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route/annotations.dart';
import 'package:auto_route_generator/src/code_builder/library_builder.dart';
import 'package:auto_route_generator/src/models/route_config.dart';
import 'package:auto_route_generator/src/models/router_config.dart';
import 'package:auto_route_generator/src/resolvers/route_config_resolver.dart';
import 'package:auto_route_generator/src/resolvers/type_resolver.dart';
import 'package:build/build.dart';
import 'package:merging_builder/merging_builder.dart';
import 'package:source_gen/source_gen.dart';

// Builder autoRouteGenerator(BuilderOptions options) {
//   // gr stands for generated router.
//   return LibraryBuilder(
//     AutoRouteGenerator(),
//     generatedExtension: '.gr.dart',
//   );
// }

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

class AutoRouteGenerator extends MergingGenerator<RouteConfig, AutoRoute> {
  late RouteConfigResolver _resolver;

  @override
  FutureOr<String> generateMergedContent(Stream<RouteConfig> stream) async {
    final routes = await stream.toList();
    // return '// ${routes.map((e) => e.pageType?.import)}';
    return generateLibrary(_resolver.routerConfig.copyWith(routes: routes));
  }

  @override
  Stream<RouteConfig> generateStream(LibraryReader library, BuildStep buildStep) async* {
    final libs = await buildStep.resolver.libraries.toList();
    _resolver = RouteConfigResolver(
        RouterConfig(
          routes: [],
          routerClassName: 'AppRouter',
          globalRouteConfig: RouteConfig(
            pathName: '',
            className: '',
            routeType: RouteType.material,
          ),
          element: null,
        ),
        TypeResolver(libs, null));
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
    assert(element is ClassElement);
    return _resolver.resolve(annotation, (element as ClassElement).thisType);
  }
}
