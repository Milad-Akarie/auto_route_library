import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:auto_route_annotation/src/route_builder_config.dart';
import 'package:build/build.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

class AggregatingBuilder extends Builder {
  /// Glob of all input files
  static final inputFiles = new Glob('lib/*.auto_route.dart');
  final List<RouteConfig> collectedRoutes;

  AggregatingBuilder(this.collectedRoutes) {
    print("-------------- AggregatingBuilder construct");
  }

  @override
  Map<String, List<String>> get buildExtensions {
    /// '$lib$' is a synthetic input that is used to
    /// force the builder to build only once.
    return {
      r'$lib$': const ['app.router.dart']
    };
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    final files = <String>[];
    print('------building');

    final lib = await buildStep.inputLibrary;
    final reader = LibraryReader(lib);

    reader.annotatedWith(TypeChecker.fromRuntime(AutoRoute)).forEach((el) {
      print("caught in aggregation ${el.element.name}");
    });

//    await for (final input in buildStep.findAssets(inputFiles)) {
//      files.add(input.path);
//      print(input.path);
//    }

    final outputFile = AssetId(buildStep.inputId.package, 'lib/app.router.dart');

    return buildStep.writeAsString(outputFile, "//generated}");
  }
}
