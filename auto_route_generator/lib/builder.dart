import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'auto_route_generator.dart';

Builder autoRouteGenerator(_) => LibraryBuilder(
      AutoRouteGenerator(),
      generatedExtension: ".auto_route.dart",
    );
