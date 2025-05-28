import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;

import '../../utils.dart';
import '../models/route_config.dart';
import '../models/router_config.dart';
import 'deferred_pages_allocator.dart';
import 'route_info_builder.dart';

/// AutoRoute imports
const autoRouteImport = 'package:auto_route/auto_route.dart';

/// Material imports
const materialImport = 'package:flutter/material.dart';

/// String type reference
const Reference stringRefer = Reference('String');

/// PageRouteInfo type reference
const Reference pageRouteType = Reference('PageRouteInfo', autoRouteImport);

/// Builds a list type reference of type [reference]
TypeReference listRefer(Reference reference, {bool nullable = false}) => TypeReference((b) => b
  ..symbol = "List"
  ..isNullable = nullable
  ..types.add(reference));

/// Generates the router library output
String generateLibrary(
  RouterConfig router, {
  required List<RouteConfig> routes,
  Set<String> ignoreForFile = const {},
}) {
  if (router.usesPartBuilder && router.deferredLoading) {
    throw ArgumentError(
        'Part-file approach will not work with deferred loading because allocator needs to mark all deferred imports!');
  }

  final emitter = DartEmitter(
    allocator: router.usesPartBuilder ? Allocator.none : DeferredPagesAllocator(routes, router.deferredLoading),
    orderDirectives: true,
    useNullSafetySyntax: true,
  );

  final deferredRoutes = routes.where((r) => r.deferredLoading == true);

  if (router.usesPartBuilder && deferredRoutes.isNotEmpty) {
    throw ArgumentError(
      'Part-file approach will not work with deferred loading because allocator needs to mark all deferred imports! ${deferredRoutes.map((e) => e.name)}',
    );
  }

  for (var i = 0; i < routes.length; i++) {
    final route = routes[i];
    if (deferredRoutes.any((e) => e.pageType == route.pageType && route.deferredLoading != true)) {
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
        for (final ignore in ignoreForFile) "ignore_for_file: $ignore",
      ])
      ..body.addAll([
        if (routes.isNotEmpty)
          ...routes
              .distinctBy((e) => e.getName(router.replaceInRouteName))
              .map((r) => buildRouteInfoAndArgs(r, router, emitter))
              .reduce((acc, a) => acc..addAll(a)),
      ]),
  );

  return DartFormatter(languageVersion: DartFormatter.latestLanguageVersion).format(
    library.accept(emitter).toString(),
  );
}
