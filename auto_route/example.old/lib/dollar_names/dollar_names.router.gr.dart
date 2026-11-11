// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:auto_route/auto_route.dart' as _i2;
import 'package:example/dollar_names/venue_page.dart' as _i1;
import 'package:material_ui/material_ui.dart' as _i3;

/// generated route for
/// [_i1.Venue$Page]
class Venue$Route extends _i2.PageRouteInfo<Venue$RouteArgs> {
  Venue$Route({
    required String user$id,
    _i3.Key? key,
    String? venue$id,
    String? tab$name,
    List<_i2.PageRouteInfo>? children,
  }) : super(
         Venue$Route.name,
         args: Venue$RouteArgs(
           user$id: user$id,
           key: key,
           venue$id: venue$id,
           tab$name: tab$name,
         ),
         rawPathParams: {'user\$id': user$id},
         rawQueryParams: {'tab\$name': tab$name},
         initialChildren: children,
       );

  static const String name = 'Venue\$Route';

  static _i2.PageInfo page = _i2.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final queryParams = data.queryParams;
      final args = data.argsAs<Venue$RouteArgs>(
        orElse: () => Venue$RouteArgs(
          user$id: pathParams.getString('user\$id'),
          tab$name: queryParams.optString('tab\$name'),
        ),
      );
      return _i1.Venue$Page(
        user$id: args.user$id,
        key: args.key,
        venue$id: args.venue$id,
        tab$name: args.tab$name,
      );
    },
  );
}

class Venue$RouteArgs {
  const Venue$RouteArgs({
    required this.user$id,
    this.key,
    this.venue$id,
    this.tab$name,
  });

  final String user$id;

  final _i3.Key? key;

  final String? venue$id;

  final String? tab$name;

  @override
  String toString() {
    return 'Venue\$RouteArgs{user\$id: ${user$id}, key: $key, venue\$id: ${venue$id}, tab\$name: ${tab$name}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Venue$RouteArgs) return false;
    return user$id == other.user$id &&
        key == other.key &&
        venue$id == other.venue$id &&
        tab$name == other.tab$name;
  }

  @override
  int get hashCode =>
      user$id.hashCode ^ key.hashCode ^ venue$id.hashCode ^ tab$name.hashCode;
}
