import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'auto_route_generator.dart';

Builder autoRouteGenerator(BuilderOptions options) {
  return SharedPartBuilder(
    [
      AutoRouteGenerator(),
    ],
    'auto_route',
  );
}
