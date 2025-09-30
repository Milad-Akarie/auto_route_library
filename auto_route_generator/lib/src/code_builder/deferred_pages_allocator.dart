import 'package:auto_route_generator/src/models/route_config.dart';
import 'package:code_builder/code_builder.dart';

/// Allocates symbols for deferred pages
class DeferredPagesAllocator implements Allocator {
  static const _doNotPrefix = ['dart:core'];

  final _imports = <String, int>{};
  var _keys = 1;

  /// The list of routes to generate
  final List<RouteConfig> routes;

  /// The default deferred loading value
  final bool defaultDeferredLoading;

  /// Default constructor
  DeferredPagesAllocator(this.routes, this.defaultDeferredLoading);

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
  Iterable<Directive> get imports => _imports.keys.map(
        (importPath) {
          if (routes.isDeferred(importPath, defaultDeferredLoading)) {
            return Directive.importDeferredAs(importPath, '_i${_imports[importPath]}');
          } else {
            return Directive.import(importPath, as: '_i${_imports[importPath]}');
          }
        },
      );
}

extension _RouteConfigList on List<RouteConfig> {
  bool isDeferred(String importPath, bool defaultDeferredLoading) {
    return mapRouteToDeferredType(importPath, defaultDeferredLoading) == _DeferredStatus.deferred;
  }

  _DeferredStatus mapRouteToDeferredType(String importPath, bool defaultDeferredLoading) {
    for (RouteConfig routeConfig in this) {
      if (routeConfig.pageType?.import == importPath) {
        return (routeConfig.deferredLoading ?? defaultDeferredLoading)
            ? _DeferredStatus.deferred
            : _DeferredStatus.none;
      }
      //todo handle this
      // if (routeConfig.childRouterConfig == null) {
      // } else {
      //   final deferredStatus = routeConfig.childRouterConfig!.routes
      //       .mapRouteToDeferredType(importPath, defaultDeferredLoading);
      //   if (deferredStatus == _DeferredStatus.Deferred) {
      //     return _DeferredStatus.Deferred;
      //   }
      //   if (deferredStatus == _DeferredStatus.None) {
      //     return defaultDeferredLoading
      //         ? _DeferredStatus.Deferred
      //         : _DeferredStatus.None;
      //   }
      // }
    }
    return _DeferredStatus.notFound;
  }
}

enum _DeferredStatus { notFound, deferred, none }
