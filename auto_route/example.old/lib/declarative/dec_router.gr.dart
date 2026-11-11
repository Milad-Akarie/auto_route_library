// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:auto_route/auto_route.dart' as _i5;
import 'package:example/declarative/age_input_screen.dart' as _i1;
import 'package:example/declarative/main_screen.dart' as _i2;
import 'package:example/declarative/name_input_screen.dart' as _i3;
import 'package:example/declarative/profile.dart' as _i7;
import 'package:example/declarative/result_screen.dart' as _i4;
import 'package:material_ui/material_ui.dart' as _i6;

/// generated route for
/// [_i1.AgeInputScreen]
class AgeInputRoute extends _i5.PageRouteInfo<AgeInputRouteArgs> {
  AgeInputRoute({
    required _i6.ValueChanged<int> onAgeSubmitted,
    _i6.Key? key,
    List<_i5.PageRouteInfo>? children,
  }) : super(
         AgeInputRoute.name,
         args: AgeInputRouteArgs(onAgeSubmitted: onAgeSubmitted, key: key),
         initialChildren: children,
       );

  static const String name = 'AgeInputRoute';

  static _i5.PageInfo page = _i5.PageInfo(
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

  final _i6.ValueChanged<int> onAgeSubmitted;

  final _i6.Key? key;

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
/// [_i2.MainScreen]
class MainRoute extends _i5.PageRouteInfo<void> {
  const MainRoute({List<_i5.PageRouteInfo>? children})
    : super(MainRoute.name, initialChildren: children);

  static const String name = 'MainRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      return const _i2.MainScreen();
    },
  );
}

/// generated route for
/// [_i3.NameInputScreen]
class NameInputRoute extends _i5.PageRouteInfo<NameInputRouteArgs> {
  NameInputRoute({
    required _i6.ValueChanged<String> onNameSubmitted,
    _i6.Key? key,
    List<_i5.PageRouteInfo>? children,
  }) : super(
         NameInputRoute.name,
         args: NameInputRouteArgs(onNameSubmitted: onNameSubmitted, key: key),
         initialChildren: children,
       );

  static const String name = 'NameInputRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NameInputRouteArgs>();
      return _i3.NameInputScreen(
        onNameSubmitted: args.onNameSubmitted,
        key: args.key,
      );
    },
  );
}

class NameInputRouteArgs {
  const NameInputRouteArgs({required this.onNameSubmitted, this.key});

  final _i6.ValueChanged<String> onNameSubmitted;

  final _i6.Key? key;

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
/// [_i4.ResultScreen]
class ResultRoute extends _i5.PageRouteInfo<ResultRouteArgs> {
  ResultRoute({
    required _i7.Profile profile,
    required _i6.VoidCallback onReset,
    _i6.Key? key,
    List<_i5.PageRouteInfo>? children,
  }) : super(
         ResultRoute.name,
         args: ResultRouteArgs(profile: profile, onReset: onReset, key: key),
         initialChildren: children,
       );

  static const String name = 'ResultRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ResultRouteArgs>();
      return _i4.ResultScreen(
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

  final _i7.Profile profile;

  final _i6.VoidCallback onReset;

  final _i6.Key? key;

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
