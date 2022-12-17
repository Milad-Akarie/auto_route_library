import 'package:auto_route_generator/auto_route_generator.dart';
import 'package:auto_route_generator/auto_router_generator.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';


Builder autoRouterBuilder(BuilderOptions options) {
  // gr stands for generated router.
  return LibraryBuilder(
    AutoRouterGenerator(),
    generatedExtension: '.gr.dart',
    allowSyntaxErrors: true,

  );
}

Builder autoRouteBuilder(BuilderOptions options) {
  return LibraryBuilder(
    AutoRouteGenerator(),
    generatedExtension: '.route.json',
    formatOutput: (generated) => generated.replaceAll(RegExp(r'//.*|\s'), ''),
    allowSyntaxErrors: true,
  );
}

