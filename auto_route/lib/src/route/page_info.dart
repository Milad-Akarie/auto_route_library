import 'package:auto_route/auto_route.dart';
import 'package:cupertino_ui/cupertino_ui.dart';

/// Holds information of the generated [RoutePage] page
///
/// Might hold more info in the future
@immutable
class PageInfo {
  /// Default constructor
  const new(this.name, {required this.builder});

  /// Builds an empty shell [PageInfo] with a const builder
  const new emptyShell(this.name) : builder = _emptyShellBuilder;

  /// Builds a new instance of [PageInfo] with the given parameters
  factory builder(String name, {required WidgetBuilderWithData builder}) {
    return PageInfo(
      name,
      builder: (data) => Builder(builder: (context) => builder(context, data)),
    );
  }

  /// The name of the generated [RoutePage]
  final String name;

  /// The builder function of the generated [RoutePage]
  final AutoRoutePageBuilder builder;

  static Widget _emptyShellBuilder(RouteData<Object?> _) {
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
  static const redirect = _NoBuilderPageInfo('#Redirect-Route');

  ///  Dummy [PageInfo] used to represent the root route
  static const root = _NoBuilderPageInfo('#Root');

  /// Creates a new instance of [PageInfo] with the given parameters
  PageInfo copyWith({String? name, AutoRoutePageBuilder? builder}) {
    return PageInfo(name ?? this.name, builder: builder ?? this.builder);
  }
}

/// Dummy [PageInfo] used to represent a redirect route
class _NoBuilderPageInfo extends PageInfo {
  /// Default constructor
  const new(super.name) : super(builder: _noBuilder);

  static Widget _noBuilder(RouteData<Object?> _) {
    throw FlutterError('PageInfo does not have a builder');
  }
}
