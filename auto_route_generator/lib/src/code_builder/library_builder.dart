import 'package:auto_route_generator/build_utils.dart';
import 'package:auto_route_generator/src/code_builder/deferred_pages_allocator.dart';
import 'package:auto_route_generator/src/code_builder/route_info_builder.dart';
import 'package:auto_route_generator/src/models/route_config.dart';
import 'package:auto_route_generator/src/models/router_config.dart';
import 'package:auto_route_generator/utils.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;

/// AutoRoute imports
const autoRouteImport = 'package:auto_route/auto_route.dart';

/// Material imports
const materialImport = 'package:flutter/material.dart';

/// String type reference
const Reference stringRefer = Reference('String');

/// PageRouteInfo type reference
const Reference pageRouteType = Reference('PageRouteInfo', autoRouteImport);

/// Builds a list type reference of type [reference]
TypeReference listRefer(Reference reference, {bool nullable = false}) => .new(
  (b) => b
    ..symbol = 'List'
    ..isNullable = nullable
    ..types.add(reference),
);

/// Throws when a route in a part file gets the name of a page class.
///
/// A part file shares the router's library, where the page is imported
/// without a prefix, so the route would hide the page and the page could no
/// longer be built. That happens to a page `replaceInRouteName` does not
/// change, such as `CostsTab`, unless its `@RoutePage` names the route.
void _throwOnRouteNamedLikePage(RouterConfig router, List<RouteConfig> routes) {
  final pageNames = routes.map((r) => r.className).toSet();
  final clashes = routes.where((r) => pageNames.contains(r.getName(router.replaceInRouteName))).toList();
  if (clashes.isEmpty) return;
  throwError(
    'A route in the part file ${router.path} gets the name of a page, which hides the page. '
    'Give the page a route name of its own:\n${clashes.map((r) {
      final name = r.getName(router.replaceInRouteName);
      return "  @RoutePage(name: '${name}Route') on ${r.className}";
    }).join('\n')}',
  );
}

/// Generates the router library output
///
/// [outputPath] is where the output is written, next to the router by
/// default, so a part file can name the router relative to it.
String generateLibrary(
  RouterConfig router, {
  required List<RouteConfig> routes,
  Set<String> ignoreForFile = const {},
  String? outputPath,
}) {
  if (router.usesPartBuilder && router.deferredLoading) {
    throw ArgumentError(
      'Part-file approach will not work with deferred loading because allocator needs to mark all deferred imports!',
    );
  }

  final emitter = DartEmitter(
    allocator: router.usesPartBuilder
        ? .none
        : DeferredPagesAllocator(routes, defaultDeferredLoading: router.deferredLoading),
    orderDirectives: true,
    useNullSafetySyntax: true,
  );

  if (router.usesPartBuilder) {
    _throwOnRouteNamedLikePage(router, routes);
  }

  final deferredRoutes = routes.where((r) => r.deferredLoading == true);

  if (router.usesPartBuilder && deferredRoutes.isNotEmpty) {
    throw ArgumentError(
      'Part-file approach will not work with deferred loading because allocator needs to mark all deferred imports! ${deferredRoutes.map((e) => e.name)}',
    );
  }

  // Dart defers a whole library, so every page imported from one file loads
  // the way the file does: on demand when any of its pages asks for it, else
  // eagerly when any opts out, else by the router default.
  final deferredByImport = <String?, bool>{};
  for (final route in routes) {
    final import = route.pageType?.import;
    final current = deferredByImport[import];
    if (current != true && route.deferredLoading != null) {
      deferredByImport[import] = route.deferredLoading!;
    }
  }
  for (var i = 0; i < routes.length; i++) {
    final route = routes[i];
    final deferredLoading = deferredByImport[route.pageType?.import];
    if (route.pageType != null && deferredLoading != null && route.deferredLoading != deferredLoading) {
      routes[i] = route.copyWith(deferredLoading: deferredLoading);
    }
  }

  final library = Library(
    (b) => b
      ..directives.addAll([
        if (router.usesPartBuilder)
          Directive.partOf(p.posix.relative(router.path, from: p.posix.dirname(outputPath ?? router.path))),
      ])
      ..comments.addAll([
        'ignore_for_file: type=lint',
        'coverage:ignore-file',
        for (final ignore in ignoreForFile) 'ignore_for_file: $ignore',
      ])
      ..body.addAll([
        if (routes.isNotEmpty)
          ...routes
              .distinctBy((e) => e.getName(router.replaceInRouteName))
              .map((r) => buildRouteInfoAndArgs(r, router, emitter))
              .reduce((acc, a) => acc..addAll(a)),
      ]),
  );

  return DartFormatter(languageVersion: DartFormatter.latestLanguageVersion).format(library.accept(emitter).toString());
}
