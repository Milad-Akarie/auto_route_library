import 'package:auto_route_generator/src/models/route_config.dart';
import 'package:code_builder/code_builder.dart';

/// Allocates symbols for deferred pages
class DeferredPagesAllocator implements Allocator {
  /// Default constructor
  DeferredPagesAllocator(this.routes, {required this.defaultDeferredLoading});
  static const _doNotPrefix = ['dart:core'];

  final _imports = <String, int>{};
  var _keys = 1;

  /// The list of routes to generate
  final List<RouteConfig> routes;

  /// The default deferred loading value
  final bool defaultDeferredLoading;

  @override
  String allocate(Reference reference) {
    final symbol = reference.symbol;
    final url = reference.url;
    if (url == null || _doNotPrefix.contains(url)) {
      return symbol!;
    }
    return '_i${_imports.putIfAbsent(url, _nextKey)}.$symbol';
  }

  int _nextKey() => _keys++;

  @override
  Iterable<Directive> get imports => _imports.keys.map((importPath) {
    if (routes.isDeferred(importPath, defaultDeferredLoading: defaultDeferredLoading)) {
      return Directive.importDeferredAs(importPath, '_i${_imports[importPath]}');
    }
    return Directive.import(importPath, as: '_i${_imports[importPath]}');
  });
}

extension _RouteConfigList on List<RouteConfig> {
  bool isDeferred(String importPath, {required bool defaultDeferredLoading}) {
    return mapRouteToDeferredType(importPath, defaultDeferredLoading: defaultDeferredLoading) == .deferred;
  }

  _DeferredStatus mapRouteToDeferredType(String importPath, {required bool defaultDeferredLoading}) {
    for (final routeConfig in this) {
      if (routeConfig.pageType?.import == importPath) {
        return (routeConfig.deferredLoading ?? defaultDeferredLoading) ? .deferred : .none;
      }
    }
    return .notFound;
  }
}

enum _DeferredStatus { notFound, deferred, none }
