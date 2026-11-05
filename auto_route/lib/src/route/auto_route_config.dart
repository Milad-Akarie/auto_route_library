import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/utils.dart';
import 'package:collection/collection.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:meta/meta.dart';

/// A Signature for a function that passes the [RouteData] and returns a [PageRoute]
typedef AutoRoutePageBuilder = Widget Function(RouteData<Object?> data);

/// Signature for a function that builds the route title
/// Used in [AutoRoutePage]
typedef TitleBuilder = String Function(BuildContext context, RouteData<Object?> data);

/// Signature for a function that builds a widget with [RouteData]
typedef WidgetBuilderWithData = Widget Function(BuildContext context, RouteData<Object?> data);

/// Signature for a function that builds the page `restorationId`
/// Used in [AutoRoutePage]
typedef RestorationIdBuilder = String Function(RouteMatch<Object?> match);

/// A route entry configuration used in `RouteMatcher`
/// to create [RouteMatch]'s from paths and [PageRouteInfo]'s
@immutable
class AutoRoute {
  /// Builds a default AutoRoute instance with any [type]
  factory({
    required PageInfo page,
    String? path,
    bool usesPathAsKey = false,
    List<AutoRouteGuard> guards = const [],
    bool fullMatch = false,
    RouteType? type,
    Map<String, Object?> meta = const {},
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

  new _({
    this._path,
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
  }) : _builder = page.builder;

  new _change({
    required this.page,
    required String this._path,
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
  }) : _builder = page.builder;

  /// Creates an AutoRoute with a single [AutoRouteGuard]
  /// callback
  factory guarded({
    required PageInfo page,
    required OnNavigation onNavigation,
    String? path,
    bool usesPathAsKey = false,
    bool fullMatch = false,
    RouteType? type,
    Map<String, Object?> meta = const {},
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

  /// .named redirect to NamedRouteDef
  factory named(
    String name,
    WidgetBuilderWithData builder, {
    String? path,
    bool usesPathAsKey = false,
    bool fullMatch = false,
    RouteType? type,
    Map<String, Object?> meta = const {},
    bool maintainState = true,
    bool fullscreenDialog = false,
    List<AutoRoute>? children,
    TitleBuilder? title,
    RestorationIdBuilder? restorationId,
    bool keepHistory = true,
    bool initial = false,
    bool allowSnapshotting = true,
  }) => NamedRouteDef(
    name: name,
    builder: builder,
    path: path,
    usesPathAsKey: usesPathAsKey,
    fullMatch: fullMatch,
    type: type,
    meta: meta,
    maintainState: maintainState,
    fullscreenDialog: fullscreenDialog,
    children: children,
    title: title,
    restorationId: restorationId,
    keepHistory: keepHistory,
    initial: initial,
    allowSnapshotting: allowSnapshotting,
  );

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
  final Map<String, Object?> meta;

  /// Indicates what kind of [PageRoute] this route will use
  /// e.g [MaterialRouteType] will create `_PageBasedMaterialPageRoute`
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

  /// Builds page title that's passed to `_PageBasedCupertinoPageRoute.title`
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

  final AutoRoutePageBuilder _builder;

  /// Returns the Widget builder function of the page
  AutoRoutePageBuilder get builder => _builder;

  /// Builds a [AutoRoutePage] from [RouteData]
  AutoRoutePage<T> buildPage<T>(RouteData<Object?> data) {
    return AutoRoutePage(child: builder(data), routeData: data);
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
  AutoRoute changePath(String newPath) => copyWith(path: newPath);

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
    Map<String, Object?>? meta,
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
      guards: guards ?? List.of(this.guards),
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
  /// Default constructor
  new({required String path, required this.redirectTo}) : super._(path: path, page: PageInfo.redirect, fullMatch: true);

  /// The target path which this route should
  /// redirect to
  final String redirectTo;

  @override
  String get name => '${page.name}-$path-$redirectTo';
}

/// Builds an [AutoRoute] instance with [RouteType.material] type
@immutable
class MaterialRoute extends AutoRoute {
  /// default constructor
  new({
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
class CupertinoRoute extends AutoRoute {
  /// Default constructor
  new({
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
class AdaptiveRoute extends AutoRoute {
  /// Default constructor
  new({
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
class CustomRoute extends AutoRoute {
  /// Default constructor
  new({
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
    Duration? duration,
    Duration? reverseDuration,
    bool opaque = true,
    bool barrierDismissible = false,
    String? barrierLabel,
    super.restorationId,
    Color? barrierColor,
    bool enablePredictiveBackGesture = false,
    RouteTransitionsBuilder? predictiveBackPageTransitionsBuilder,
    bool enableCupertinoBackGesture = false,
  }) : super._(
         type: RouteType.custom(
           transitionsBuilder: transitionsBuilder,
           customRouteBuilder: customRouteBuilder,
           duration: duration,
           reverseDuration: reverseDuration,
           opaque: opaque,
           barrierDismissible: barrierDismissible,
           barrierLabel: barrierLabel,
           barrierColor: barrierColor,
           enablePredictiveBackGesture: enablePredictiveBackGesture,
           predictiveBackPageTransitionsBuilder: predictiveBackPageTransitionsBuilder,
           enableCupertinoBackGesture: enableCupertinoBackGesture,
         ),
       );
}

/// Builds an [AutoRoute] instance with a direct page builder
///
/// this is meant to be used for simple routes that don't need
/// code generation
class NamedRouteDef extends AutoRoute {
  /// Default constructor
  new({
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
  new guarded({
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
  new shell({
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
  new(String name, {super.path, super.children, super.fullMatch, super.restorationId, super.initial})
    : super._(page: PageInfo(name, builder: (_) => const SizedBox()));
}

/// Builds a simplified [AutoRoute] instance for internal usage
/// Used by [RootStackRouter] as root-node
@internal
class DummyRootRoute extends AutoRoute {
  /// Default constructor
  new({required String path, super.children, super.fullMatch, super.restorationId})
    : super._(page: PageInfo.root, path: path);
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
/// Mainly used by `RouteMatcher`
@immutable
class RouteCollection {
  /// Default constructor
  new(this._routesMap, [this._subCollections = const {}])
    : assert(_routesMap.isNotEmpty, 'A route collection needs at least one route.');

  /// Creates a Map of config-entries from [routes]
  ///
  /// also handles validating defined paths and
  /// auto-generating the non-defined ones
  ///
  /// if this [RouteCollection] is created by the router [root] will be true
  /// else if it's created by a parent route-entry it will be false
  factory fromList(List<AutoRoute> routes, {bool root = false, OnGeneratePath onGeneratePath = defaultPathGenerator}) {
    final routesMarkedInitial = routes.where((e) => e.initial);
    throwIf(
      routesMarkedInitial.length > 1,
      'Invalid data\nThere are more than one initial route in this collection\n${routesMarkedInitial.map((e) => e.name)}',
    );

    final targetInitialPath = root ? '/' : '';
    var routesMap = <String, AutoRoute>{};
    final subCollections = <String, RouteCollection>{};
    var hasValidInitialPath = false;
    for (final r in routes) {
      if (r.hasSubTree) {
        subCollections[r.name] = RouteCollection.fromList(r.children!, onGeneratePath: onGeneratePath);
      }

      // Replaced below when the route's path is generated.
      // ignore: avoid-unnecessary-local-variable
      var routeToUse = r;
      if (r._path != null) {
        throwIf(!root && r.path.startsWith('/'), 'Sub-paths can not start with a "/": ${r.path}');
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
          assert(
            !path.startsWith('/'),
            '"/" is added automatically based on route level, generated path should not have a leading "/"',
          );
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
      final redirectRoute = RedirectRoute(path: targetInitialPath, redirectTo: routesMarkedInitial.first.path);
      routesMap = {redirectRoute.name: redirectRoute, ...routesMap};
    }
    final collection = RouteCollection(routesMap, subCollections);
    // Debug builds only: an app that pushes such a route in code works, and
    // must not start failing once it ships.
    assert(() {
      if (root) _throwIfPathsRepeat(collection);
      return true;
    }(), 'Two routes have the same path');
    return collection;
  }

  /// Throws a [FlutterError] naming two routes of the tree under [root] whose
  /// full paths are the same, as `/a` twice, or the same but for the names
  /// of their params, as `/meal/:id` and `/meal/:mealId`.
  ///
  /// A url opens the first of them, so the second is never opened by its
  /// url. A route and its descendants may share a path: a child with an
  /// empty path is the page its parent shows first. A redirect may come
  /// before a route with its path, to send that url elsewhere while the
  /// route's children stay reachable; a redirect after it would never run.
  ///
  /// Runs in debug builds only.
  static void _throwIfPathsRepeat(RouteCollection root) {
    final byPattern = <String, List<(AutoRoute, String)>>{};
    void visit(RouteCollection collection, String parentPath, List<AutoRoute> ancestors) {
      for (final route in collection.routes) {
        final path = _joinPaths(parentPath, route.path);
        // Params match any segment whatever their names.
        final pattern = path.replaceAll(RegExp(':[^/?]+'), ':');
        final others = byPattern.putIfAbsent(pattern, () => []);
        for (final (other, otherPath) in others) {
          if (other is RedirectRoute || ancestors.contains(other)) continue;
          final (first, second) = (_describe(other), _describe(route));
          final named = otherPath == path
              ? '$first and $second have the same path, $path,'
              : '$first, $otherPath, and $second, $path, have the same path,';
          throwIf(true, '$named so a link to it opens only $first. Give one of them another path.');
        }
        others.add((route, path));
        if (route.hasSubTree) {
          visit(collection.subCollectionOf(route.name), path, [...ancestors, route]);
        }
      }
    }

    visit(root, '', const []);
  }

  // A redirect's name is made of its paths, so it is described by them.
  static String _describe(AutoRoute route) =>
      route is RedirectRoute ? 'the redirect from ${route.path} to ${route.redirectTo}' : route.name;

  static String _joinPaths(String parent, String child) {
    if (parent.isEmpty || child.isEmpty) return parent + child;
    return parent.endsWith('/') ? '$parent$child' : '$parent/$child';
  }

  final Map<String, AutoRoute> _routesMap;
  final Map<String, RouteCollection> _subCollections;

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
    assert(_subCollections[key] != null, '$key does not have children');
    return _subCollections[key]!;
  }

  /// Lists these routes, and the routes nested under each, as a tree with one
  /// route a line: its full path and its name.
  ///
  /// A full path joins the paths of the route's parents with its own, so
  /// `/shop` with the child `:id` reads `/shop/:id`, and an initial child with
  /// the path `''` reads as its parent's path. A [RedirectRoute] shows the path
  /// it redirects to, as `→ /shop`, in place of a name. Routes keep the order
  /// they were declared in, which is the order the matcher tries them.
  ///
  /// The collection of a [RootStackRouter] lists every route of the app; a
  /// nested router's collection lists its own routes, with paths relative to
  /// it. A [RouteNotFoundFailure] carries the root's tree, and printing
  /// `router.routeCollection.toTreeString()` shows the app's routes while
  /// debugging:
  ///
  /// ```text
  /// ├─ /  HomeRoute
  /// ├─ /shop  ShopRoute
  /// │  ├─ /shop  ProductsRoute
  /// │  └─ /shop/:id  ProductRoute
  /// └─ /old-shop  → /shop
  /// ```
  String toTreeString() => _treeLines('', '').join('\n');

  List<String> _treeLines(String parentPath, String indent) {
    final lines = <String>[];
    final all = routes.toList();
    for (final (index, route) in all.indexed) {
      final isLast = index == all.length - 1;
      final fullPath = _joinPaths(parentPath, route.path);
      final label = route is RedirectRoute ? '→ ${route.redirectTo}' : route.name;
      lines.add('$indent${isLast ? '└─' : '├─'} $fullPath  $label');
      if (_subCollections[route.name] case final children?) {
        lines.addAll(children._treeLines(fullPath, '$indent${isLast ? '   ' : '│  '}'));
      }
    }
    return lines;
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
      for (final child in node.children!) {
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
          const MapEquality<Object?, Object?>().equals(_routesMap, other._routesMap);

  @override
  int get hashCode => const MapEquality<Object?, Object?>().hash(_routesMap);

  /// Default path generator
  static String defaultPathGenerator(AutoRoute r) {
    return toKebabCase(r.name);
  }
}
