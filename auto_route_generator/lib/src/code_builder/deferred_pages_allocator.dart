import 'package:auto_route_generator/src/models/route_config.dart';
import 'package:code_builder/code_builder.dart';

class DeferredPagesAllocator implements Allocator {
  static const _doNotPrefix = ['dart:core'];

  final _imports = <String, int>{};
  var _keys = 1;

  final List<RouteConfig> routes;

  DeferredPagesAllocator(this.routes);

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
          if (routes.containsPageImport(importPath)) {
            return Directive.importDeferredAs(
                importPath, '_i${_imports[importPath]}');
          } else {
            return Directive.import(importPath,
                as: '_i${_imports[importPath]}');
          }
        },
      );
}

extension _RouteConfigList on List<RouteConfig> {
  bool containsPageImport(String importPath) {
    return any((routeConfig) {
      if (routeConfig.pageType?.import == importPath) {
        return true;
      }
      if (routeConfig.childRouterConfig == null) {
        return false;
      }
      return routeConfig.childRouterConfig!.routes
          .containsPageImport(importPath);
    });
  }
}
