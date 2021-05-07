import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

import '../../utils.dart';
import '../models/importable_type.dart';
import '../models/route_config.dart';
import '../models/router_config.dart';
import 'root_router_builder.dart';
import 'route_info_builder.dart';

const autoRouteImport = 'package:auto_route/auto_route.dart';
const materialImport = 'package:flutter/material.dart';

const Reference stringRefer = Reference('String');
const Reference pageRouteType = Reference('PageRouteInfo', autoRouteImport);
const Reference requiredAnnotation = Reference('required', materialImport);

TypeReference listRefer(Reference reference, {bool nullable = false}) =>
    TypeReference((b) => b
      ..symbol = "List"
      ..isNullable = nullable
      ..types.add(reference));

String generateLibrary(RouterConfig config) {
  final emitter = DartEmitter(
    allocator: Allocator.simplePrefixing(),
    orderDirectives: true,
    useNullSafetySyntax: true,
  );

  var allRouters = config.collectAllRoutersIncludingParent;
  List<RouteConfig> allRoutes =
      allRouters.fold(<RouteConfig>[], (acc, a) => acc..addAll(a.routes));

  final nonRedirectRoutes =
      allRoutes.where((r) => r.routeType != RouteType.redirect);
  final checkedRoutes = <RouteConfig>[];
  nonRedirectRoutes.forEach((route) {
    throwIf(
      (checkedRoutes.any((r) =>
          r.routeName == route.routeName && r.pathName != route.pathName)),
      'Duplicate route names must have the same path! [${route.name}]\nNote: Unless specified, route name is generated from page name.',
      element: config.element,
    );
    checkedRoutes.add(route);
  });

  var allGuards = allRoutes.fold<Set<ImportableType>>(
    {},
    (acc, a) => acc..addAll(a.guards),
  );

  final library = Library(
    (b) => b
      ..body.addAll([
        buildRouterConfig(config, allGuards, allRoutes),
        ...allRoutes
            .where((r) => r.routeType != RouteType.redirect)
            .distinctBy((e) => e.routeName)
            .map((r) => buildRouteInfoAndArgs(r, config, emitter))
            .reduce((acc, a) => acc..addAll(a)),
      ]),
  );

  return DartFormatter().format(library.accept(emitter).toString());
}
