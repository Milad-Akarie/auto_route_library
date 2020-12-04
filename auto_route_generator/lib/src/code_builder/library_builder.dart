import 'package:auto_route_generator/route_config_resolver.dart';
import 'package:auto_route_generator/src/code_builder/route_info_builder.dart';
import 'package:auto_route_generator/src/code_builder/router_config_builder.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

import 'args_class_builder.dart';

const autoRouteImport = 'package:auto_route/auto_route.dart';
const materialImport = 'package:flutter/material.dart';

const Reference stringRefer = Reference('String');
const Reference pageRouteType = Reference('PageRouteInfo', autoRouteImport);
const Reference requiredAnnotation = Reference('required', materialImport);

TypeReference listRefer(Reference reference) => TypeReference((b) => b
  ..symbol = "List"
  ..types.add(reference));

String generateLibrary(RouterConfig config) {
  var allRouters = config.collectAllRoutersIncludingParent;
  var allRoutes = allRouters.map((r) => r.routes).reduce((acc, a) => acc..addAll(a));
  var allGuards =
      allRoutes.where((r) => r.guards?.isNotEmpty == true).map((r) => r.guards).reduce((acc, a) => acc..addAll(a));

  final library = Library(
    (b) => b
      ..body.addAll([
        ...allRoutes.map(buildRouteInfo),
        ...allRoutes.map(buildArgsClass),
        buildRouterConfig(config, allGuards, allRoutes),
      ]),
  );

  final emitter = DartEmitter(Allocator.simplePrefixing());
  print('${library.accept(emitter)}');
  return DartFormatter().format('${library.accept(emitter)}');
}
