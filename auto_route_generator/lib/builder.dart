import 'package:auto_route_generator/auto_route_builder.dart';
import 'package:auto_route_generator/auto_router_generator.dart';
import 'package:auto_route_generator/auto_route_generator.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:file/local.dart';
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
  return AutoRouteMergingBuilder(generator: AutoRouteGenerator());
}


