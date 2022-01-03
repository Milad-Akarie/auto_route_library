import 'package:auto_route_generator/src/models/route_config.dart';
import 'package:auto_route_generator/utils.dart';
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
        (u) {
          var routeElement =
              routes.firstOrNull((element) => element.pageType?.import == u);
          if (routeElement != null) {
            return Directive.importDeferredAs(u, '_i${_imports[u]}');
          } else {
            return Directive.import(u, as: '_i${_imports[u]}');
          }
        },
      );
}
