import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/utils.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';

typedef TitleBuilder = String Function(BuildContext context, RouteData data);

@immutable
class AutoRoute {
  final String name;
  final String? _path;
  final bool fullMatch;
  final RouteCollection? _children;
  final String? redirectTo;
  final List<AutoRouteGuard> guards;
  final bool usesPathAsKey;
  final Map<String, dynamic> meta;
  final RouteType? type;
  final bool fullscreenDialog;
  final bool maintainState;
  final TitleBuilder? title;
  final bool keepHistory;

  AutoRoute._({
    required this.name,
    String? path,
    this.usesPathAsKey = false,
    this.guards = const [],
    this.fullMatch = false,
    this.redirectTo,
    this.type,
    this.meta = const {},
    this.maintainState = true,
    this.fullscreenDialog = false,
    this.title,
    this.keepHistory = true,
    List<AutoRoute>? children,
  })  : _path = path,
        _children = children != null ? RouteCollection.from(children) : null;

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
    bool keepHistory = true,
  }) {
    return AutoRoute._(
      name: page.name,
      path: path,
      fullMatch: fullMatch,
      maintainState: maintainState,
      fullscreenDialog: fullMatch,
      meta: meta,
      type: type,
      usesPathAsKey: usesPathAsKey,
      guards: guards,
      children: children,
      title: title,
      keepHistory: keepHistory,
    );
  }

  String get path => _path!;

  bool get hasSubTree => _children != null;

  RouteCollection? get children => _children;

  bool get isRedirect => redirectTo != null;

  @override
  String toString() {
    return 'RouteConfig{name: $name}';
  }

  AutoRoute copyWith({
    String? name,
    String? path,
    bool? fullMatch,
    String? redirectTo,
    List<AutoRouteGuard>? guards,
    bool? usesPathAsKey,
    Map<String, dynamic>? meta,
    RouteType? type,
    bool? fullscreenDialog,
    bool? maintainState,
    TitleBuilder? title,
    bool? keepHistory,
  }) {
    return AutoRoute._(
      name: name ?? this.name,
      path: path ?? _path,
      fullMatch: fullMatch ?? this.fullMatch,
      redirectTo: redirectTo ?? this.redirectTo,
      guards: guards ?? this.guards,
      usesPathAsKey: usesPathAsKey ?? this.usesPathAsKey,
      meta: meta ?? this.meta,
      type: type ?? this.type,
      fullscreenDialog: fullscreenDialog ?? this.fullscreenDialog,
      maintainState: maintainState ?? this.maintainState,
      title: title ?? this.title,
      keepHistory: keepHistory ?? this.keepHistory,
    );
  }
}

@immutable
class RedirectRoute extends AutoRoute {
  RedirectRoute({
    required super.path,
    required String redirectTo,
  }) : super._(
          name: 'Redirect#$path',
          fullMatch: true,
          redirectTo: redirectTo,
        );
}

@immutable
class MaterialRoute extends AutoRoute {
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
  }) : super._(
          name: page.name,
          type: const RouteType.material(),
        );
}

@immutable
class CupertinoRoute extends AutoRoute {
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
    super.keepHistory,
  }) : super._(name: name.toString(), type: const RouteType.cupertino());
}

@immutable
class AdaptiveRoute extends AutoRoute {
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
    bool opaque = true,
    super.keepHistory,
  }) : super._(
          name: page.name,
          type: RouteType.adaptive(opaque: opaque),
        );
}

@immutable
class CustomRoute extends AutoRoute {
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
    Function? transitionsBuilder,
    Function? customRouteBuilder,
    int? durationInMilliseconds,
    int? reverseDurationInMilliseconds,
    bool opaque = true,
    bool barrierDismissible = true,
    String? barrierLabel,
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

@visibleForTesting
class TestRoute extends AutoRoute {
  TestRoute(
    String name, {
    required String path,
    super.children,
    super.redirectTo,
    super.fullMatch,
  }) : super._(name: name, path: path);
}

class RouteCollection {
  final Map<String, AutoRoute> _routesMap;

  RouteCollection(this._routesMap) : assert(_routesMap.isNotEmpty);

  factory RouteCollection.from(List<AutoRoute> routes, {bool root = false}) {
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
        routesMap[r.name] = r.copyWith(
          path: _generateRoutePath(r.name, root),
        );
      }
    }

    return RouteCollection(routesMap);
  }

  Iterable<AutoRoute> get routes => _routesMap.values;

  AutoRoute? operator [](String key) => _routesMap[key];

  bool containsKey(String key) => _routesMap.containsKey(key);

  RouteCollection subCollectionOf(String key) {
    assert(this[key]?.children != null, "$key does not have children");
    return this[key]!.children!;
  }

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
