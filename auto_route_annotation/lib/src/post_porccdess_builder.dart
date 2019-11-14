import 'dart:async';

import 'package:build/build.dart';

class PostProcBuilder extends PostProcessBuilder {
  @override
  FutureOr<void> build(PostProcessBuildStep buildStep) {
    print('removing');
//    final outputFile = AssetId(buildStep.inputId.package, 'lib/router.dart');

    buildStep.deletePrimaryInput();
//    buildStep.writeAsString(buildStep.inputId, "// post proccess");

//    final outputFile = AssetId(buildStep.inputId.package, 'lib/router.dart');
//    buildStep.deletePrimaryInput();
//    return buildStep.writeAsString(outputFile, "// aggregating builder");
  }

  @override
  Iterable<String> get inputExtensions => [".router.dart"];
}
