import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'auto_route_generator.dart';

Builder autoRouteGenerator(BuilderOptions options) {
  // gr stands for generated router.
  return LibraryBuilder(
    AutoRouteGenerator(),
    generatedExtension: '.gr.dart',
  );
}
