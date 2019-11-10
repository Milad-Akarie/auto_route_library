import 'package:auto_route/route_gen_annotation.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'route_builder_config.dart';

const TypeChecker autoRoute = TypeChecker.fromRuntime(AutoRoute);

class RouteCollector extends Generator {
  final List<RouteConfig> collectedRoutes;

  RouteCollector(this.collectedRoutes);

  @override
  generate(LibraryReader library, BuildStep buildStep) async {
    final inputId = buildStep.inputId;
    library.annotatedWith(autoRoute).forEach((el) {
      final RouteConfigBuilder configBuilder =
          RouteConfigBuilder(library: library, inputId: inputId, annotatedElement: el);
      collectedRoutes.add(configBuilder.build());
    });

    return null;
  }
}
