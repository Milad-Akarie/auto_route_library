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
  const PageInfo(this.name, {required this.builder}) ;

/// Builds an empty shell [PageInfo] with a const builder
  const PageInfo.emptyShell(this.name) : builder = _emptyShellBuilder;


  static Widget _emptyShellBuilder(RouteData _){
    return const AutoRouter();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageInfo &&
          runtimeType == other.runtimeType &&
          builder == other.builder &&
          name == other.name;

  @override
  int get hashCode => name.hashCode ^ builder.hashCode;

  /// Dummy [PageInfo] used to represent a redirect route
  static final redirect = _NoBuilderPageInfo('#Redirect-Route');

  ///  Dummy [PageInfo] used to represent the root route
  static final root = _NoBuilderPageInfo('#Root');
}

/// Dummy [PageInfo] used to represent a redirect route
class _NoBuilderPageInfo extends PageInfo {
  /// Default constructor
  _NoBuilderPageInfo(super.name)
      : super(
          builder: (data) {
            throw FlutterError('RedirectPageInfo does not have a builder');
          },
        );
}
