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
import 'package:material_ui/material_ui.dart' as _i3;

/// generated route for
/// [_i1.AgeInputScreen]
class AgeInputRoute extends _i2.PageRouteInfo<AgeInputRouteArgs> {
  AgeInputRoute({
    required _i3.ValueChanged<int> onAgeSubmitted,
    _i3.Key? key,
    List<_i2.PageRouteInfo>? children,
  }) : super(
         AgeInputRoute.name,
         args: AgeInputRouteArgs(onAgeSubmitted: onAgeSubmitted, key: key),
         initialChildren: children,
       );

  static const String name = 'AgeInputRoute';

  static _i2.PageInfo page = _i2.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AgeInputRouteArgs>();
      return _i1.AgeInputScreen(
        onAgeSubmitted: args.onAgeSubmitted,
        key: args.key,
      );
    },
  );
}

class AgeInputRouteArgs {
  const AgeInputRouteArgs({required this.onAgeSubmitted, this.key});

  final _i3.ValueChanged<int> onAgeSubmitted;

  final _i3.Key? key;

  @override
  String toString() {
    return 'AgeInputRouteArgs{onAgeSubmitted: $onAgeSubmitted, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AgeInputRouteArgs) return false;
    return onAgeSubmitted == other.onAgeSubmitted && key == other.key;
  }

  @override
  int get hashCode => onAgeSubmitted.hashCode ^ key.hashCode;
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
    required _i3.ValueChanged<String> onNameSubmitted,
    _i3.Key? key,
    List<_i2.PageRouteInfo>? children,
  }) : super(
         NameInputRoute.name,
         args: NameInputRouteArgs(onNameSubmitted: onNameSubmitted, key: key),
         initialChildren: children,
       );

  static const String name = 'NameInputRoute';

  static _i2.PageInfo page = _i2.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NameInputRouteArgs>();
      return _i1.NameInputScreen(
        onNameSubmitted: args.onNameSubmitted,
        key: args.key,
      );
    },
  );
}

class NameInputRouteArgs {
  const NameInputRouteArgs({required this.onNameSubmitted, this.key});

  final _i3.ValueChanged<String> onNameSubmitted;

  final _i3.Key? key;

  @override
  String toString() {
    return 'NameInputRouteArgs{onNameSubmitted: $onNameSubmitted, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NameInputRouteArgs) return false;
    return onNameSubmitted == other.onNameSubmitted && key == other.key;
  }

  @override
  int get hashCode => onNameSubmitted.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i1.ResultScreen]
class ResultRoute extends _i2.PageRouteInfo<ResultRouteArgs> {
  ResultRoute({
    required _i1.Profile profile,
    required _i3.VoidCallback onReset,
    _i3.Key? key,
    List<_i2.PageRouteInfo>? children,
  }) : super(
         ResultRoute.name,
         args: ResultRouteArgs(profile: profile, onReset: onReset, key: key),
         initialChildren: children,
       );

  static const String name = 'ResultRoute';

  static _i2.PageInfo page = _i2.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ResultRouteArgs>();
      return _i1.ResultScreen(
        profile: args.profile,
        onReset: args.onReset,
        key: args.key,
      );
    },
  );
}

class ResultRouteArgs {
  const ResultRouteArgs({
    required this.profile,
    required this.onReset,
    this.key,
  });

  final _i1.Profile profile;

  final _i3.VoidCallback onReset;

  final _i3.Key? key;

  @override
  String toString() {
    return 'ResultRouteArgs{profile: $profile, onReset: $onReset, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ResultRouteArgs) return false;
    return profile == other.profile &&
        onReset == other.onReset &&
        key == other.key;
  }

  @override
  int get hashCode => profile.hashCode ^ onReset.hashCode ^ key.hashCode;
}
