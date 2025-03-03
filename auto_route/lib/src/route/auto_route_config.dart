import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/utils.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:meta/meta.dart';

/// A Signature for a function that passes the [RouteData] and returns a [PageRoute]
typedef AutoRoutePageBuilder = Widget Function(RouteData data);

/// Signature for a function that builds the route title
/// Used in [AutoRoutePage]
typedef TitleBuilder = String Function(BuildContext context, RouteData data);

/// Signature for a function that builds a widget with [RouteData]
typedef WidgetBuilderWithData = Widget Function(BuildContext context, RouteData data);

/// Signature for a function that builds the page [restorationId]
/// Used in [AutoRoutePage]
typedef RestorationIdBuilder = String Function(RouteMatch match);

/// A route entry configuration used in [RouteMatcher]
/// to create [RouteMatch]'s from paths and [PageRouteInfo]'s
@immutable
class AutoRoute {
  /// The name of page this route should map to
  final PageInfo page;
  final String? _path;

  /// Weather to match this route's path as fullMatch
  final bool fullMatch;

  /// The list of [AutoRoute] children of this route
  final List<AutoRoute>? children;

  /// The list of [AutoRouteGuard]'s the matched route
  /// will go through before being presented
  final List<AutoRouteGuard> guards;

  /// If set to true the [AutoRoutePage] will use the matched-path
  /// as it's key otherwise [name] will be used
  final bool usesPathAsKey;

  /// a Map of dynamic data that can be accessed by
  /// [RouteData.meta] when the route is created
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

  /// Whether the target route should allow snapshotting.
  /// Passed To [PageRoute.allowSnapshotting]
  final bool allowSnapshotting;

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

  /// Marks route as initial destination of a router
  ///
  /// initial will auto-generate initial paths
  /// for routes with defined-paths
  ///
  /// if used with a non-initial defined path it auto-generates
  /// a RedirectRoute() to that path
  final bool initial;

  /// Helper getter to get the name of the page
  String get name => page.name;

  final AutoRoutePageBuilder _pageBuilder;

  /// Returns the Widget builder function of the page
  AutoRoutePageBuilder get builder => _pageBuilder;

  /// Builds a [AutoRoutePage] from [RouteData]
  AutoRoutePage<T> buildPage<T>(RouteData data) {
    return AutoRoutePage<T>(
      child: builder(data),
      routeData: data,
    );
  }

  AutoRoute._({
    String? path,
    required this.page,
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
    this.allowSnapshotting = true,
    this.initial = false,
    this.children,
  })  : _path = path,
        _pageBuilder = page.builder;

  AutoRoute._change({
    required this.page,
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
    required this.children,
    required this.initial,
    required this.allowSnapshotting,
  })  : _path = path,
        _pageBuilder = page.builder;

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
    bool initial = false,
    bool allowSnapshotting = true,
  }) {
    return AutoRoute._(
      page: page,
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
      initial: initial,
      allowSnapshotting: allowSnapshotting,
    );
  }

  /// Creates an AutoRoute with a single [AutoRouteGuard]
  /// callback
  factory AutoRoute.guarded({
    required PageInfo page,
    required OnNavigation onNavigation,
    String? path,
    bool usesPathAsKey = false,
    bool fullMatch = false,
    RouteType? type,
    Map<String, dynamic> meta = const {},
    bool maintainState = true,
    bool fullscreenDialog = false,
    List<AutoRoute>? children,
    TitleBuilder? title,
    RestorationIdBuilder? restorationId,
    bool keepHistory = true,
    bool initial = false,
    bool allowSnapshotting = true,
  }) {
    return AutoRoute._(
      page: page,
      path: path,
      fullMatch: fullMatch,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
      meta: meta,
      type: type,
      usesPathAsKey: usesPathAsKey,
      guards: [AutoRouteGuard.simple(onNavigation)],
      restorationId: restorationId,
      children: children,
      title: title,
      keepHistory: keepHistory,
      initial: initial,
      allowSnapshotting: allowSnapshotting,
    );
  }

  /// The path defined by user or automatically-added
  /// By [RouteCollection.fromList]
  String get path => _path ?? '';

  /// Whether is route is a parent route
  bool get hasSubTree => children != null && children!.isNotEmpty;

  @override
  String toString() {
    return 'AutoRoute{name: ${page.name}}';
  }

  /// A simplified copyWith
  ///
  /// Returns a new AutoRoute instance with the provided path
  AutoRoute changePath(String path) => copyWith(path: path);

  /// A simplified copyWith
  ///
  /// Returns a new AutoRoute instance with the provided details overriding.
  AutoRoute copyWith({
    RouteType? type,
    PageInfo? page,
    String? path,
    bool? usesPathAsKey,
    List<AutoRouteGuard>? guards,
    bool? fullMatch,
    Map<String, dynamic>? meta,
    bool? maintainState,
    bool? fullscreenDialog,
    List<AutoRoute>? children,
    TitleBuilder? title,
    RestorationIdBuilder? restorationId,
    bool? keepHistory,
    bool? initial,
    bool? allowSnapshotting,
  }) {
    return AutoRoute._change(
      type: type ?? this.type,
      page: page ?? this.page,
      path: path ?? this.path,
      usesPathAsKey: usesPathAsKey ?? this.usesPathAsKey,
      guards: guards ?? List.from(this.guards),
      //copy
      fullMatch: fullMatch ?? this.fullMatch,
      meta: meta ?? this.meta,
      maintainState: maintainState ?? this.maintainState,
      fullscreenDialog: fullscreenDialog ?? this.fullscreenDialog,
      children: children ?? this.children,
      //copy
      title: title ?? this.title,
      restorationId: restorationId ?? this.restorationId,
      keepHistory: keepHistory ?? this.keepHistory,
      initial: initial ?? this.initial,
      allowSnapshotting: allowSnapshotting ?? this.allowSnapshotting,
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
    required String path,
    required this.redirectTo,
  }) : super._(
          path: path,
          page: PageInfo.redirect,
          fullMatch: true,
        );

  @override
  String get name => "${page.name}-$path-$redirectTo";
}

/// Builds an [AutoRoute] instance with [RouteType.material] type
@immutable
class MaterialRoute extends AutoRoute {
  /// default constructor
  MaterialRoute({
    required super.page,
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
    super.initial,
    super.allowSnapshotting = true,
    bool enablePredictiveBackGesture = false,
    RouteTransitionsBuilder? predictiveBackPageTransitionsBuilder,
  }) : super._(
          type: RouteType.material(
            enablePredictiveBackGesture: enablePredictiveBackGesture,
            predictiveBackPageTransitionsBuilder: predictiveBackPageTransitionsBuilder,
          ),
        );
}

/// Builds an [AutoRoute] instance with [RouteType.cupertino] type
@immutable
class CupertinoRoute<R> extends AutoRoute {
  /// Default constructor
  CupertinoRoute({
    required super.page,
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
    super.initial,
    super.allowSnapshotting = true,
  }) : super._(type: const RouteType.cupertino());
}

/// Builds an [AutoRoute] instance with [RouteType.adaptive] type
@immutable
class AdaptiveRoute<R> extends AutoRoute {
  /// Default constructor
  AdaptiveRoute({
    required super.page,
    super.fullscreenDialog,
    super.maintainState,
    super.fullMatch = false,
    super.initial,
    super.guards,
    super.usesPathAsKey = false,
    super.path,
    super.children,
    super.meta = const {},
    super.title,
    super.restorationId,
    bool opaque = true,
    super.keepHistory,
    super.allowSnapshotting = true,
    bool enablePredictiveBackGesture = false,
    RouteTransitionsBuilder? predictiveBackPageTransitionsBuilder,
  }) : super._(
          type: RouteType.adaptive(
            opaque: opaque,
            enablePredictiveBackGesture: enablePredictiveBackGesture,
            predictiveBackPageTransitionsBuilder: predictiveBackPageTransitionsBuilder,
          ),
        );
}

/// Builds an [AutoRoute] instance with [RouteType.custom] type
@immutable
class CustomRoute<R> extends AutoRoute {
  /// Default constructor
  CustomRoute({
    required super.page,
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
    super.initial,
    super.allowSnapshotting = true,
    RouteTransitionsBuilder? transitionsBuilder,
    CustomRouteBuilder? customRouteBuilder,
    @Deprecated('Use duration instead') int? durationInMilliseconds,
    @Deprecated('Use reverseDuration instead') int? reverseDurationInMilliseconds,
    Duration? duration,
    Duration? reverseDuration,
    bool opaque = true,
    bool barrierDismissible = true,
    String? barrierLabel,
    super.restorationId,
    Color? barrierColor,
    bool enablePredictiveBackGesture = false,
    RouteTransitionsBuilder? predictiveBackPageTransitionsBuilder,
  })  : assert(durationInMilliseconds == null || duration == null, 'Use duration instead of durationInMilliseconds'),
        assert(reverseDurationInMilliseconds == null || reverseDuration == null,
            'Use reverseDuration instead of reverseDurationInMilliseconds'),
        super._(
          type: RouteType.custom(
            transitionsBuilder: transitionsBuilder,
            customRouteBuilder: customRouteBuilder,
            duration: duration,
            reverseDuration: reverseDuration,
            // todo: remove deprecated members
            // ignore: deprecated_member_use_from_same_package
            durationInMilliseconds: durationInMilliseconds,
            // todo: remove deprecated members
            // ignore: deprecated_member_use_from_same_package
            reverseDurationInMilliseconds: reverseDurationInMilliseconds,
            opaque: opaque,
            barrierDismissible: barrierDismissible,
            barrierLabel: barrierLabel,
            barrierColor: barrierColor,
            enablePredictiveBackGesture: enablePredictiveBackGesture,
            predictiveBackPageTransitionsBuilder: predictiveBackPageTransitionsBuilder,
          ),
        );
}

/// Builds an [AutoRoute] instance with a direct page builder
///
/// this is meant to be used for simple routes that don't need
/// code generation
class NamedRouteDef extends AutoRoute {
  /// Default constructor
  NamedRouteDef({
    super.path,
    required String name,
    super.fullscreenDialog,
    super.maintainState,
    super.fullMatch = false,
    super.guards,
    super.usesPathAsKey = false,
    super.children,
    super.meta = const {},
    super.title,
    super.keepHistory,
    super.initial,
    super.allowSnapshotting = true,
    super.restorationId,
    super.type,
    required WidgetBuilderWithData builder,
  }) : super._(page: PageInfo.builder(name, builder: builder));

  /// Creates a guarded route
  NamedRouteDef.guarded({
    super.path,
    required String name,
    required OnNavigation onNavigation,
    super.fullscreenDialog,
    super.maintainState,
    super.fullMatch = false,
    super.usesPathAsKey = false,
    super.children,
    super.meta = const {},
    super.title,
    super.keepHistory,
    super.initial,
    super.allowSnapshotting = true,
    super.restorationId,
    super.type,
    required WidgetBuilderWithData builder,
  }) : super._(
          guards: [AutoRouteGuard.simple(onNavigation)],
          page: PageInfo.builder(name, builder: builder),
        );

  /// Creates a guarded route
  NamedRouteDef.shell({
    required String name,
    super.path,
    super.fullscreenDialog,
    super.maintainState,
    super.fullMatch = false,
    super.usesPathAsKey = false,
    required super.children,
    super.guards,
    super.meta = const {},
    super.title,
    super.keepHistory,
    super.initial,
    super.allowSnapshotting = true,
    super.restorationId,
    super.type,
  }) : super._(page: PageInfo.emptyShell(name));
}

/// Builds a simplified [AutoRoute] instance for test
@visibleForTesting
class TestRoute extends AutoRoute {
  /// Default constructor
  TestRoute(
    String name, {
    super.path,
    super.children,
    super.fullMatch,
    super.restorationId,
    super.initial,
  }) : super._(page: PageInfo(name, builder: (_) => const SizedBox()));
}

/// Builds a simplified [AutoRoute] instance for internal usage
/// Used by [RootStackRouter] as root-node
@internal
class DummyRootRoute extends AutoRoute {
  /// Default constructor
  DummyRootRoute({
    required String path,
    super.children,
    super.fullMatch,
    super.restorationId,
  }) : super._(page: PageInfo.root, path: path);
}

/// Signature for a function that generates a path for a route name
typedef OnGeneratePath = String Function(AutoRoute route);

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
  final Map<String, RouteCollection> _subCollections;

  /// Default constructor
  RouteCollection(this._routesMap, [this._subCollections = const {}]) : assert(_routesMap.isNotEmpty);

  /// Creates a Map of config-entries from [routes]
  ///
  /// also handles validating defined paths and
  /// auto-generating the non-defined ones
  ///
  /// if this [RouteCollection] is created by the router [root] will be true
  /// else if it's created by a parent route-entry it will be false
  factory RouteCollection.fromList(List<AutoRoute> routes,
      {bool root = false, OnGeneratePath onGeneratePath = defaultPathGenerator}) {
    final routesMarkedInitial = routes.where((e) => e.initial);
    throwIf(routesMarkedInitial.length > 1,
        'Invalid data\nThere are more than one initial route in this collection\n${routesMarkedInitial.map((e) => e.name)}');

    final targetInitialPath = root ? '/' : '';
    var routesMap = <String, AutoRoute>{};
    final subCollections = <String, RouteCollection>{};
    var hasValidInitialPath = false;
    for (var r in routes) {
      if (r.hasSubTree) {
        subCollections[r.name] = RouteCollection.fromList(
          r.children!,
          onGeneratePath: onGeneratePath,
        );
      }

      var routeToUse = r;
      if (r._path != null) {
        throwIf(
          !root && r.path.startsWith('/'),
          'Sub-paths can not start with a "/": ${r.path}',
        );
        throwIf(
          root && !r.path.startsWith(RegExp('[/]|[*]')),
          'Root-paths must start with a "/" or be a wild-card:  ${r.path}',
        );
        routeToUse = r;
      } else {
        final String generatedPath;
        if (r.initial) {
          generatedPath = root ? '/' : '';
        } else {
          final path = onGeneratePath(r);
          assert(!path.startsWith('/'),
              '"/" is added automatically based on route level, generated path should not have a leading "/"');
          generatedPath = root ? '/$path' : path;
        }
        routeToUse = r.changePath(generatedPath);
      }
      hasValidInitialPath |= routeToUse.path == targetInitialPath;
      if (routesMap.containsKey(r.name)) {
        throw ArgumentError.value(r.name, 'name', 'Route name must be unique');
      }
      routesMap[r.name] = routeToUse;
    }
    if (!hasValidInitialPath && routesMarkedInitial.isNotEmpty) {
      final redirectRoute = RedirectRoute(
        path: targetInitialPath,
        redirectTo: routesMarkedInitial.first.path,
      );
      routesMap = {
        redirectRoute.name: redirectRoute,
        ...routesMap,
      };
    }
    return RouteCollection(routesMap, subCollections);
  }

  /// Returns the values of [_routesMap] as iterable
  Iterable<AutoRoute> get routes => _routesMap.values;

  /// Helper to get the route-entry corresponding to [key]
  AutoRoute? operator [](String key) => _routesMap[key];

  /// Helper to check if a route name exists inside of [_routesMap]
  bool containsKey(String key) => _routesMap.containsKey(key);

  /// Returns the sub route-entries of the route corresponding with [key]
  ///
  /// Throws and error if corresponding route has not children
  RouteCollection subCollectionOf(String key) {
    assert(_subCollections[key] != null, "$key does not have children");
    return _subCollections[key]!;
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
      for (AutoRoute child in node.children!) {
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

  /// Default path generator
  static String defaultPathGenerator(AutoRoute r) {
    return toKebabCase(r.name);
  }
}
