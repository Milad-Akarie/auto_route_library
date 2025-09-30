// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i2;
import 'package:example/nested-navigation/nested_navigation.router.dart' as _i1;

/// generated route for
/// [_i1.FirstScreen]
class FirstRoute extends _i2.PageRouteInfo<void> {
  const FirstRoute({List<_i2.PageRouteInfo>? children})
      : super(FirstRoute.name, initialChildren: children);

  static const String name = 'FirstRoute';

  static _i2.PageInfo page = _i2.PageInfo(
    name,
    builder: (data) {
      return const _i1.FirstScreen();
    },
  );
}

/// generated route for
/// [_i1.HostScreen]
class HostRoute extends _i2.PageRouteInfo<void> {
  const HostRoute({List<_i2.PageRouteInfo>? children})
      : super(HostRoute.name, initialChildren: children);

  static const String name = 'HostRoute';

  static _i2.PageInfo page = _i2.PageInfo(
    name,
    builder: (data) {
      return const _i1.HostScreen();
    },
  );
}

/// generated route for
/// [_i1.SecondScreen]
class SecondRoute extends _i2.PageRouteInfo<void> {
  const SecondRoute({List<_i2.PageRouteInfo>? children})
      : super(SecondRoute.name, initialChildren: children);

  static const String name = 'SecondRoute';

  static _i2.PageInfo page = _i2.PageInfo(
    name,
    builder: (data) {
      return const _i1.SecondScreen();
    },
  );
}
