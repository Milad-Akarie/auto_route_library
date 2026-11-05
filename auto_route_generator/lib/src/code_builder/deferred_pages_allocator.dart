import 'package:auto_route_generator/src/models/route_config.dart';
import 'package:code_builder/code_builder.dart';
import 'package:path/path.dart' as p;

/// Allocates symbols for deferred pages
class DeferredPagesAllocator implements Allocator {
  /// Default constructor
  new(
    this._routes, {
    required this._defaultDeferredLoading,
    required this._outputPath,
  });
  static const _doNotPrefix = ['dart:core'];

  final _imports = <String, int>{};
  var _keys = 1;

  /// The list of routes to generate
  final List<RouteConfig> _routes;

  /// The default deferred loading value
  final bool _defaultDeferredLoading;

  /// Where the router is written, as a path inside its package.
  ///
  /// Imports of files outside `lib/` are written relative to it, since they
  /// have no `package:` URI and a Flutter build rejects `asset:` imports.
  final String _outputPath;

  @override
  String allocate(Reference reference) {
    final symbol = reference.symbol!;
    final url = reference.url;
    if (url == null || _doNotPrefix.contains(url)) {
      return symbol;
    }
    return '_i${_imports.putIfAbsent(url, _nextKey)}.$symbol';
  }

  int _nextKey() => _keys++;

  @override
  Iterable<Directive> get imports => _imports.entries.map((entry) {
    final importPath = entry.key;
    final uri = _importUri(importPath);
    if (_routes.isDeferred(
      importPath,
      defaultDeferredLoading: _defaultDeferredLoading,
    )) {
      return Directive.importDeferredAs(uri, '_i${entry.value}');
    }
    return Directive.import(uri, as: '_i${entry.value}');
  });

  String _importUri(String importPath) {
    final uri = Uri.parse(importPath);
    if (uri.scheme != 'asset' || uri.pathSegments.length < 2) return importPath;
    // The first segment of an asset: URI is the package.
    return p.posix.relative(
      uri.pathSegments.skip(1).join('/'),
      from: p.posix.dirname(_outputPath),
    );
  }
}

extension _RouteConfigList on List<RouteConfig> {
  bool isDeferred(String importPath, {required bool defaultDeferredLoading}) {
    return mapRouteToDeferredType(
          importPath,
          defaultDeferredLoading: defaultDeferredLoading,
        ) ==
        .deferred;
  }

  _DeferredStatus mapRouteToDeferredType(
    String importPath, {
    required bool defaultDeferredLoading,
  }) {
    for (final routeConfig in this) {
      if (routeConfig.pageType?.import == importPath) {
        return (routeConfig.deferredLoading ?? defaultDeferredLoading)
            ? .deferred
            : .none;
      }
    }
    return .notFound;
  }
}

enum _DeferredStatus { notFound, deferred, none }
