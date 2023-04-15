import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/utils.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:meta/meta.dart';

/// Signature for a function that builds the route title
/// Used in [AutoRoutePage]
typedef TitleBuilder = String Function(BuildContext context, RouteData data);

/// Signature for a function that builds the page [restorationId]
/// Used in [AutoRoutePage]
typedef RestorationIdBuilder = String Function(RouteMatch match);

/// A route entry configuration used in [RouteMatcher]
/// to create [RouteMatch]'s from paths and [PageRouteInfo]'s
@immutable
class AutoRoute {
  /// The name of page this route should map to
  final String name;
  final String? _path;

  /// Weather to match this route's path as fullMatch
  final bool fullMatch;
  final RouteCollection? _children;

  /// The list of [AutoRouteGuard]'s the matched route
  /// will go through before being presented
  final List<AutoRouteGuard> guards;

  /// If set to true the [AutoRoutePage] will use the matched-path
  /// as it's key otherwise [name] will be used
  final bool usesPathAsKey;

  /// a Map of dynamic data that can be accessed by
  /// [RouteData.mete] when the route is created
  final Map<String, dynamic> meta;

  /// Indicates what kind of [PageRoute] this route will use
  /// e.g [MaterialRouteType] will create [_PageBasedMaterialPageRoute]
  final RouteType? type;

  /// Whether to treat the target route as a fullscreenDialog.
  /// Passed To [PageRoute.fullscreenDialog]
  final bool fullscreenDialog;

  /// Whether the target route should maintain it's state.
  /// Passed To [PageRoute.maintainState]
  final bool maintainState;

  /// Builds page title that's passed to [_PageBasedCupertinoPageRoute.title]
  /// where it can be used by [CupertinoNavigationBar]
  ///
  /// it can also be used manually by calling [RouteData.title] inside widgets
  final TitleBuilder? title;

  /// Builds a String value that that's passed to
  /// [AutoRoutePage.restorationId]
  final RestorationIdBuilder? restorationId;

  /// Whether the target route should be kept in stack
  /// after another route is pushed above it
  final bool keepHistory;

  AutoRoute._({
    required this.name,
    String? path,
    this.usesPathAsKey = false,
    this.guards = const [],
    this.fullMatch = false,
    this.type,
    this.meta = const {},
    this.maintainState = true,
    this.fullscreenDialog = false,
    this.title,
    this.keepHistory = true,
    this.restorationId,
    List<AutoRoute>? children,
  })  : _path = path,
        _children =
            children != null ? RouteCollection.fromList(children) : null;

  const AutoRoute._changePath({
    required this.name,
    required String path,
    required this.usesPathAsKey,
    required this.guards,
    required this.fullMatch,
    required this.type,
    required this.meta,
    required this.maintainState,
    required this.fullscreenDialog,
    required this.title,
    required this.keepHistory,
    required this.restorationId,
    required RouteCollection? children,
  })  : _path = path,
        _children = children;

  /// Builds a default AutoRoute instance with any [type]
  factory AutoRoute({
    required PageInfo page,
    String? path,
    bool usesPathAsKey = false,
    List<AutoRouteGuard> guards = const [],
    bool fullMatch = false,
    RouteType? type,
    Map<String, dynamic> meta = const {},
    bool maintainState = true,
    bool fullscreenDialog = false,
    List<AutoRoute>? children,
    TitleBuilder? title,
    RestorationIdBuilder? restorationId,
    bool keepHistory = true,
  }) {
    return AutoRoute._(
      name: page.name,
      path: path,
      fullMatch: fullMatch,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
      meta: meta,
      type: type,
      usesPathAsKey: usesPathAsKey,
      guards: guards,
      restorationId: restorationId,
      children: children,
      title: title,
      keepHistory: keepHistory,
    );
  }

  /// The path defined by user or automatically-added
  /// By [RouteCollection.fromList]
  String get path => _path ?? '';

  /// Whether is route is a parent route
  bool get hasSubTree => _children != null;

  /// The nested child-entries of this route
  ///
  /// returns null if this route has no child-entries
  RouteCollection? get children => _children;

  @override
  String toString() {
    return 'RouteConfig{name: $name}';
  }

  /// A simplified copyWith
  ///
  /// Returns a new AutoRoute instance with the provided path
  AutoRoute changePath(String path) {
    return AutoRoute._changePath(
      name: name,
      path: path,
      fullMatch: fullMatch,
      guards: guards,
      usesPathAsKey: usesPathAsKey,
      meta: meta,
      type: type,
      fullscreenDialog: fullscreenDialog,
      maintainState: maintainState,
      title: title,
      keepHistory: keepHistory,
      children: children,
      restorationId: restorationId,
    );
  }
}

/// Builds a Redirect AutoRoute instance with no type
///
/// Redirect routes don't map to a page, instead they
/// Map to an existing route-entry that maps to a page
@immutable
class RedirectRoute extends AutoRoute {
  /// The target path which this route should
  /// redirect to
  final String redirectTo;

  /// Default constructor
  RedirectRoute({
    required super.path,
    required this.redirectTo,
  }) : super._(
          name: 'Redirect#$path',
          fullMatch: true,
        );
}

/// Builds an [AutoRoute] instance with [RouteType.material] type
@immutable
class MaterialRoute extends AutoRoute {
  /// default constructor
  MaterialRoute({
    required PageInfo page,
    super.path,
    super.fullscreenDialog,
    super.maintainState,
    super.fullMatch = false,
    super.guards,
    super.usesPathAsKey = false,
    super.children,
    super.meta = const {},
    super.title,
    super.keepHistory,
    super.restorationId,
  }) : super._(
          name: page.name,
          type: const RouteType.material(),
        );
}

/// Builds an [AutoRoute] instance with [RouteType.cupertino] type
@immutable
class CupertinoRoute extends AutoRoute {
  /// Default constructor
  CupertinoRoute({
    required Type name,
    super.fullscreenDialog,
    super.maintainState,
    super.fullMatch = false,
    super.guards,
    super.usesPathAsKey = false,
    super.children,
    super.meta = const {},
    super.path,
    super.title,
    super.restorationId,
    super.keepHistory,
  }) : super._(name: name.toString(), type: const RouteType.cupertino());
}

/// Builds an [AutoRoute] instance with [RouteType.adaptive] type
@immutable
class AdaptiveRoute extends AutoRoute {
  /// Default constructor
  AdaptiveRoute({
    required PageInfo page,
    super.fullscreenDialog,
    super.maintainState,
    super.fullMatch = false,
    super.guards,
    super.usesPathAsKey = false,
    super.path,
    super.children,
    super.meta = const {},
    super.title,
    super.restorationId,
    bool opaque = true,
    super.keepHistory,
  }) : super._(
          name: page.name,
          type: RouteType.adaptive(opaque: opaque),
        );
}

/// Builds an [AutoRoute] instance with [RouteType.custom] type
@immutable
class CustomRoute extends AutoRoute {
  /// Default constructor
  CustomRoute({
    required PageInfo page,
    super.fullscreenDialog,
    super.maintainState,
    super.fullMatch = false,
    super.guards,
    super.usesPathAsKey = false,
    super.children,
    super.meta = const {},
    super.title,
    super.path,
    super.keepHistory,
    RouteTransitionsBuilder? transitionsBuilder,
    CustomRouteBuilder? customRouteBuilder,
    int? durationInMilliseconds,
    int? reverseDurationInMilliseconds,
    bool opaque = true,
    bool barrierDismissible = true,
    String? barrierLabel,
    super.restorationId,
    Color? barrierColor,
  }) : super._(
          name: page.name,
          type: RouteType.custom(
            transitionsBuilder: transitionsBuilder,
            customRouteBuilder: customRouteBuilder,
            durationInMilliseconds: durationInMilliseconds,
            reverseDurationInMilliseconds: reverseDurationInMilliseconds,
            opaque: opaque,
            barrierDismissible: barrierDismissible,
            barrierLabel: barrierLabel,
            barrierColor: barrierColor,
          ),
        );
}

/// Builds a simplified [AutoRoute] instance for test
@visibleForTesting
class TestRoute extends AutoRoute {
  /// Default constructor
  TestRoute(
    String name, {
    required String path,
    super.children,
    super.fullMatch,
    super.restorationId,
  }) : super._(name: name, path: path);
}

/// Builds a simplified [AutoRoute] instance for internal usage
/// Used by [RootStackRouter] as root-node
@internal
class DummyRootRoute extends AutoRoute {
  /// Default constructor
  DummyRootRoute(
    String name, {
    required String path,
    super.children,
    super.fullMatch,
    super.restorationId,
  }) : super._(name: name, path: path);
}

/// Holds a single set of config-entries
///
/// it makes accessing routes by name easier
/// by creating a Map on init
///
/// it also has some helper-methods and getters
/// to deal with config-entries
///
/// Mainly used by [RouteMatcher]
class RouteCollection {
  final Map<String, AutoRoute> _routesMap;

  RouteCollection._(this._routesMap) : assert(_routesMap.isNotEmpty);

  /// Creates a Map of config-entries from [routes]
  ///
  /// also handles validating defined paths and
  /// auto-generating the non-defined ones
  ///
  /// if this [RouteCollection] is created by the router [root] will be true
  /// else if it's created by a parent route-entry it will be false
  factory RouteCollection.fromList(List<AutoRoute> routes,
      {bool root = false}) {
    final routesMap = <String, AutoRoute>{};
    for (var r in routes) {
      if (r._path != null) {
        throwIf(
          !root && r.path.startsWith('/'),
          'Sub-paths can not start with a "/"',
        );
        throwIf(
          root && !r.path.startsWith(RegExp('[/]|[*]')),
          'Root-paths must start with a "/" or be a wild-card',
        );
        routesMap[r.name] = r;
      } else {
        routesMap[r.name] = r.changePath(
          _generateRoutePath(r.name, root),
        );
      }
    }

    return RouteCollection._(routesMap);
  }

  /// Returns the values of [_routesMap] as iterable
  Iterable<AutoRoute> get routes => _routesMap.values;

  /// Helper to get the route-entry corresponding with [key]
  AutoRoute? operator [](String key) => _routesMap[key];

  /// Helper to check if a route name exists inside of [_routesMap]
  bool containsKey(String key) => _routesMap.containsKey(key);

  /// Returns the sub route-entries of the route corresponding with [key]
  ///
  /// Throws and error if corresponding route has not children
  RouteCollection subCollectionOf(String key) {
    assert(this[key]?.children != null, "$key does not have children");
    return this[key]!.children!;
  }

  /// Finds the track to a certain route in the routes-tree
  ///
  /// This is mainly used to try adding parent routes to the
  /// navigation sequences when pushing child routes without
  /// adding their parents to stack first
  ///
  /// returns and empty list if the track is not found
  List<AutoRoute> findPathTo(String routeName) {
    final track = <AutoRoute>[];
    for (final route in routes) {
      if (_findPath(route, routeName, track)) {
        break;
      }
    }
    return track;
  }

  bool _findPath(AutoRoute node, String routeName, List<AutoRoute> track) {
    if (node.name == routeName) {
      track.add(node);
      return true;
    }

    if (node.hasSubTree) {
      for (AutoRoute child in node.children!.routes) {
        if (_findPath(child, routeName, track)) {
          track.insert(0, node);
          return true;
        }
      }
    }

    return false;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteCollection &&
          runtimeType == other.runtimeType &&
          const MapEquality().equals(_routesMap, other._routesMap);

  @override
  int get hashCode => const MapEquality().hash(_routesMap);

  static String _generateRoutePath(String name, bool root) {
    final kebabCased = toKebabCase(name);
    return root ? '/$kebabCased' : kebabCased;
  }
}
