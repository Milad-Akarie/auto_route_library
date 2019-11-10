import 'package:auto_route/router_annotation.dart';
import 'package:auto_route_annotation/src/router_class_generator.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'route_builder_config.dart';

const TypeChecker routerApp = TypeChecker.fromRuntime(RouterApp);

class RouteGenerator extends Generator {
  final List<RouteConfig> collectedRoutes;
  RouteGenerator(this.collectedRoutes);

  @override
  generate(LibraryReader library, BuildStep buildStep) async {
    if (library.annotatedWith(routerApp).isNotEmpty) {
      return RouterClassGenerator(collectedRoutes).generate();
    }
    return null;
  }
}
