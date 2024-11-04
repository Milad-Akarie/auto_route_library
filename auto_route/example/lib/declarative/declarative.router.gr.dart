// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i2;
import 'package:example/declarative/declarative.router.dart' as _i1;
import 'package:flutter/material.dart' as _i3;

/// generated route for
/// [_i1.AgeInputScreen]
class AgeInputRoute extends _i2.PageRouteInfo<AgeInputRouteArgs> {
  AgeInputRoute({
    required _i3.ValueChanged<int> onAgeSubmitted,
    List<_i2.PageRouteInfo>? children,
  }) : super(
          AgeInputRoute.name,
          args: AgeInputRouteArgs(onAgeSubmitted: onAgeSubmitted),
          initialChildren: children,
        );

  static const String name = 'AgeInputRoute';

  static _i2.PageInfo page = _i2.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AgeInputRouteArgs>();
      return _i1.AgeInputScreen(
        key: args.key,
        onAgeSubmitted: args.onAgeSubmitted,
      );
    },
  );
}

class AgeInputRouteArgs extends _i2.BaseRouteArgs {
  const AgeInputRouteArgs({
    required this.onAgeSubmitted,
    super.key,
  });

  final _i3.ValueChanged<int> onAgeSubmitted;

  @override
  String toString() {
    return 'AgeInputRouteArgs{onAgeSubmitted: $onAgeSubmitted}';
  }
}

/// generated route for
/// [_i1.MainScreen]
class MainRoute extends _i2.PageRouteInfo<Null> {
  const MainRoute({List<_i2.PageRouteInfo>? children})
      : super(
          MainRoute.name,
          initialChildren: children,
        );

  static const String name = 'MainRoute';

  static _i2.PageInfo page = _i2.PageInfo(
    name,
    builder: (data) {
      return _i1.MainScreen();
    },
  );
}

/// generated route for
/// [_i1.NameInputScreen]
class NameInputRoute extends _i2.PageRouteInfo<NameInputRouteArgs> {
  NameInputRoute({
    required _i3.ValueChanged<String> onNameSubmitted,
    List<_i2.PageRouteInfo>? children,
  }) : super(
          NameInputRoute.name,
          args: NameInputRouteArgs(onNameSubmitted: onNameSubmitted),
          initialChildren: children,
        );

  static const String name = 'NameInputRoute';

  static _i2.PageInfo page = _i2.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NameInputRouteArgs>();
      return _i1.NameInputScreen(
        key: args.key,
        onNameSubmitted: args.onNameSubmitted,
      );
    },
  );
}

class NameInputRouteArgs extends _i2.BaseRouteArgs {
  const NameInputRouteArgs({
    required this.onNameSubmitted,
    super.key,
  });

  final _i3.ValueChanged<String> onNameSubmitted;

  @override
  String toString() {
    return 'NameInputRouteArgs{onNameSubmitted: $onNameSubmitted}';
  }
}

/// generated route for
/// [_i1.ResultScreen]
class ResultRoute extends _i2.PageRouteInfo<ResultRouteArgs> {
  ResultRoute({
    required _i1.Profile profile,
    required _i3.VoidCallback onReset,
    List<_i2.PageRouteInfo>? children,
  }) : super(
          ResultRoute.name,
          args: ResultRouteArgs(
            profile: profile,
            onReset: onReset,
          ),
          initialChildren: children,
        );

  static const String name = 'ResultRoute';

  static _i2.PageInfo page = _i2.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ResultRouteArgs>();
      return _i1.ResultScreen(
        key: args.key,
        profile: args.profile,
        onReset: args.onReset,
      );
    },
  );
}

class ResultRouteArgs extends _i2.BaseRouteArgs {
  const ResultRouteArgs({
    required this.profile,
    required this.onReset,
    super.key,
  });

  final _i1.Profile profile;

  final _i3.VoidCallback onReset;

  @override
  String toString() {
    return 'ResultRouteArgs{profile: $profile, onReset: $onReset}';
  }
}
