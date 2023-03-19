import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

import '../../utils.dart';
import '../models/route_config.dart';
import '../models/router_config.dart';
import 'deferred_pages_allocator.dart';
import 'root_router_builder.dart';
import 'route_info_builder.dart';
import 'package:path/path.dart' as p;

const autoRouteImport = 'package:auto_route/auto_route.dart';
const materialImport = 'package:flutter/material.dart';
const foundationImport = 'package:flutter/foundation.dart';

const Reference stringRefer = Reference('String');
const Reference pageRouteType = Reference('PageRouteInfo', autoRouteImport);
const Reference requiredAnnotation = Reference('required', materialImport);

TypeReference listRefer(Reference reference, {bool nullable = false}) =>
    TypeReference((b) => b
      ..symbol = "List"
      ..isNullable = nullable
      ..types.add(reference));

String generateLibrary(
  RouterConfig router, {
  required List<RouteConfig> routes,
}) {
  throwIf(
    router.usesPartBuilder && router.deferredLoading,
    'Part-file approach will not work with deferred loading because allocator needs to mark all deferred imports!',
  );

  final emitter = DartEmitter(
    allocator: router.usesPartBuilder
        ? Allocator.none
        : DeferredPagesAllocator(routes, router.deferredLoading),
    orderDirectives: true,
    useNullSafetySyntax: true,
  );

  final deferredRoutes = routes.where((r) => r.deferredLoading == true);
  throwIf(
    router.usesPartBuilder && deferredRoutes.isNotEmpty,
    'Part-file approach will not work with deferred loading because allocator needs to mark all deferred imports! ${deferredRoutes.map((e) => e.name)}',
  );

  for (var i = 0; i < routes.length; i++) {
    final route = routes[i];
    if (deferredRoutes.any(
        (e) => e.pageType == route.pageType && route.deferredLoading != true)) {
      routes[i] = route.copyWith(deferredLoading: true);
    }
  }

  final library = Library(
    (b) => b
      ..directives.addAll([
        if (router.usesPartBuilder) Directive.partOf(p.basename(router.path)),
      ])
      ..comments.addAll([
        "ignore_for_file: type=lint",
        "coverage:ignore-file",
      ])
      ..body.addAll([
        buildRouterConfig(router, routes),
        if (routes.isNotEmpty)
          ...routes
              .distinctBy((e) => e.getName(router.replaceInRouteName))
              .map((r) => buildRouteInfoAndArgs(r, router, emitter))
              .reduce((acc, a) => acc..addAll(a)),
      ]),
  );

  return DartFormatter().format(library.accept(emitter).toString());
}
