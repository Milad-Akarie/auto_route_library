import 'package:auto_route_annotation/src/auto_route_generator.dart';

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

Builder autoRouteGenerator(_) => LibraryBuilder(AutoRouteGenerator(), generatedExtension: ".auto_route_config.json");
