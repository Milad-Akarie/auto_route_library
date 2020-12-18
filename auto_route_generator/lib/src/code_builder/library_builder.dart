import 'package:auto_route_generator/route_config_resolver.dart';
import 'package:auto_route_generator/src/code_builder/route_info_builder.dart';
import 'package:auto_route_generator/src/code_builder/router_config_builder.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

import '../../import_resolver.dart';

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
  var allRoutes = allRouters.fold(<RouteConfig>[], (acc, a) => acc..addAll(a.routes));
  var allGuards =
      allRoutes.where((r) => r.guards?.isNotEmpty == true).fold(<ImportableType>{}, (acc, a) => acc..addAll(a.guards));

  final library = Library(
    (b) => b
      ..body.addAll([
        buildRouterConfig(config, allGuards, allRoutes),
        ...allRoutes.where((r) => r.routeType != RouteType.redirect).map((r) => buildRouteInfo(r, config)),
        // ...allRoutes.where((r) => r.parameters?.isNotEmpty == true).map(buildArgsClass),
      ]),
  );

  final emitter = DartEmitter(Allocator.simplePrefixing());
  return DartFormatter().format(library.accept(emitter).toString());
}
