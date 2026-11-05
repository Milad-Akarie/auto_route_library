// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:auto_route/auto_route.dart' as _i2;
import 'package:example/deferred/deferred_first_page.dart' deferred as _i1;

/// generated route for
/// [_i1.DeferredFirstPage]
class DeferredFirstRoute extends _i2.PageRouteInfo<void> {
  const DeferredFirstRoute({List<_i2.PageRouteInfo>? children})
    : super(DeferredFirstRoute.name, initialChildren: children);

  static const String name = 'DeferredFirstRoute';

  static _i2.PageInfo page = _i2.PageInfo(
    name,
    builder: (data) {
      return _i2.DeferredWidget(_i1.loadLibrary, () => _i1.DeferredFirstPage());
    },
  );
}

/// generated route for
/// [_i1.DeferredSecondPage]
class DeferredSecondRoute extends _i2.PageRouteInfo<void> {
  const DeferredSecondRoute({List<_i2.PageRouteInfo>? children})
    : super(DeferredSecondRoute.name, initialChildren: children);

  static const String name = 'DeferredSecondRoute';

  static _i2.PageInfo page = _i2.PageInfo(
    name,
    builder: (data) {
      return _i2.DeferredWidget(
        _i1.loadLibrary,
        () => _i1.DeferredSecondPage(),
      );
    },
  );
}
