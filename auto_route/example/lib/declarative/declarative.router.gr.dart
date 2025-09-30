// dart format width=80
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
    _i3.Key? key,
    required _i3.ValueChanged<int> onAgeSubmitted,
    List<_i2.PageRouteInfo>? children,
  }) : super(
          AgeInputRoute.name,
          args: AgeInputRouteArgs(key: key, onAgeSubmitted: onAgeSubmitted),
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

class AgeInputRouteArgs {
  const AgeInputRouteArgs({this.key, required this.onAgeSubmitted});

  final _i3.Key? key;

  final _i3.ValueChanged<int> onAgeSubmitted;

  @override
  String toString() {
    return 'AgeInputRouteArgs{key: $key, onAgeSubmitted: $onAgeSubmitted}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AgeInputRouteArgs) return false;
    return key == other.key && onAgeSubmitted == other.onAgeSubmitted;
  }

  @override
  int get hashCode => key.hashCode ^ onAgeSubmitted.hashCode;
}

/// generated route for
/// [_i1.MainScreen]
class MainRoute extends _i2.PageRouteInfo<void> {
  const MainRoute({List<_i2.PageRouteInfo>? children})
      : super(MainRoute.name, initialChildren: children);

  static const String name = 'MainRoute';

  static _i2.PageInfo page = _i2.PageInfo(
    name,
    builder: (data) {
      return const _i1.MainScreen();
    },
  );
}

/// generated route for
/// [_i1.NameInputScreen]
class NameInputRoute extends _i2.PageRouteInfo<NameInputRouteArgs> {
  NameInputRoute({
    _i3.Key? key,
    required _i3.ValueChanged<String> onNameSubmitted,
    List<_i2.PageRouteInfo>? children,
  }) : super(
          NameInputRoute.name,
          args: NameInputRouteArgs(key: key, onNameSubmitted: onNameSubmitted),
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

class NameInputRouteArgs {
  const NameInputRouteArgs({this.key, required this.onNameSubmitted});

  final _i3.Key? key;

  final _i3.ValueChanged<String> onNameSubmitted;

  @override
  String toString() {
    return 'NameInputRouteArgs{key: $key, onNameSubmitted: $onNameSubmitted}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NameInputRouteArgs) return false;
    return key == other.key && onNameSubmitted == other.onNameSubmitted;
  }

  @override
  int get hashCode => key.hashCode ^ onNameSubmitted.hashCode;
}

/// generated route for
/// [_i1.ResultScreen]
class ResultRoute extends _i2.PageRouteInfo<ResultRouteArgs> {
  ResultRoute({
    _i3.Key? key,
    required _i1.Profile profile,
    required _i3.VoidCallback onReset,
    List<_i2.PageRouteInfo>? children,
  }) : super(
          ResultRoute.name,
          args: ResultRouteArgs(key: key, profile: profile, onReset: onReset),
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

class ResultRouteArgs {
  const ResultRouteArgs({
    this.key,
    required this.profile,
    required this.onReset,
  });

  final _i3.Key? key;

  final _i1.Profile profile;

  final _i3.VoidCallback onReset;

  @override
  String toString() {
    return 'ResultRouteArgs{key: $key, profile: $profile, onReset: $onReset}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ResultRouteArgs) return false;
    return key == other.key &&
        profile == other.profile &&
        onReset == other.onReset;
  }

  @override
  int get hashCode => key.hashCode ^ profile.hashCode ^ onReset.hashCode;
}
