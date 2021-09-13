import 'package:auto_route_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';

Future testGenerator({
  required String generatedFile,
  required String router,
}) async {
  Logger.root.level = Level.INFO;

  final anotherBuilder = autoRouteGenerator(BuilderOptions({}));

  return await testBuilder(
    anotherBuilder,
    {
      'a|lib/router.dart': router,
    },
    outputs: {
      'a|lib/router.gr.dart': generatedFile,
    },
    onLog: print,
    reader: await PackageAssetReader.currentIsolate(),
  );
}
