import 'package:auto_route_generator/route_config_resolver.dart';
import 'package:auto_route_generator/src/code_builder/root_router_builder.dart';
import 'package:auto_route_generator/src/code_builder/route_info_builder.dart';
import 'package:auto_route_generator/utils.dart';
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

  List<RouteConfig> allRoutes =
      allRouters.fold(<RouteConfig>[], (acc, a) => acc..addAll(a.routes));

  var routeNames = allRoutes
      .where((r) => r.routeType != RouteType.redirect)
      .map((r) => r.routeName);
  var checkedNames = <String>[];
  routeNames.forEach((name) {
    throwIf(
      checkedNames.contains(name),
      'There are more than one rout with the name [$name], route names must be unique!\nNote: Unless specified, route name is generated from page name.',
      element: config.element,
    );
    checkedNames.add(name);
  });

  var allGuards = allRoutes
      .where((r) => r.guards?.isNotEmpty == true)
      .fold(<ImportableType>{}, (acc, a) => acc..addAll(a.guards));

  final library = Library(
    (b) => b
      ..body.addAll([
        buildRouterConfig(config, allGuards, allRoutes),
        ...allRoutes
            .where((r) => r.routeType != RouteType.redirect)
            .map((r) => buildRouteInfo(r, config)),
      ]),
  );

  final emitter = DartEmitter(Allocator.simplePrefixing(), true, true);
  return DartFormatter().format(library.accept(emitter).toString());
}
