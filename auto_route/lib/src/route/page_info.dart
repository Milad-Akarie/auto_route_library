import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';

/// Holds information of the generated [RoutePage] page
///
/// Might hold more info in the future
class PageInfo {
  /// The name of the generated [RoutePage]
  final String name;

  /// The builder function of the generated [RoutePage]
  final AutoRoutePageBuilder builder;

  /// Default constructor
  const PageInfo(this.name, {required this.builder});

  /// Builds an empty shell [PageInfo] with a const builder
  const PageInfo.emptyShell(this.name) : builder = _emptyShellBuilder;

  static Widget _emptyShellBuilder(RouteData _) {
    return const AutoRouter();
  }

  /// Builds a new instance of [PageInfo] with the given parameters
  factory PageInfo.builder(String name, {required WidgetBuilderWithData builder}) {
    return PageInfo(
      name,
      builder: (data) => Builder(
        builder: (context) => builder(context, data),
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageInfo && runtimeType == other.runtimeType && builder == other.builder && name == other.name;

  @override
  int get hashCode => name.hashCode ^ builder.hashCode;

  /// Dummy [PageInfo] used to represent a redirect route
  static const redirect = _NoBuilderPageInfo('#Redirect-Route');

  ///  Dummy [PageInfo] used to represent the root route
  static const root = _NoBuilderPageInfo('#Root');

  /// Creates a new instance of [PageInfo] with the given parameters
  PageInfo copyWith({
    String? name,
    AutoRoutePageBuilder? builder,
  }) {
    return PageInfo(
      name ?? this.name,
      builder: builder ?? this.builder,
    );
  }
}

/// Dummy [PageInfo] used to represent a redirect route
class _NoBuilderPageInfo extends PageInfo {
  /// Default constructor
  const _NoBuilderPageInfo(super.name)
      : super(
          builder: _noBuilder,
        );

  static Widget _noBuilder(RouteData _) {
    throw FlutterError('PageInfo does not have a builder');
  }
}
