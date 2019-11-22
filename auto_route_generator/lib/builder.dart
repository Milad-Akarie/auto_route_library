import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'auto_route_generator.dart';

Builder autoRouteGenerator(BuilderOptions options) {
  print("build function ---------------------------");
  print(options.config.toString());
  return LibraryBuilder(
      AutoRouteGenerator(),
      generatedExtension: ".auto_route.dart",
    );
}
