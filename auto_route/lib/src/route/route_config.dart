import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/utils.dart';
import 'package:flutter/cupertino.dart';
import '../matcher/route_matcher.dart';

typedef TitleBuilder = String Function(BuildContext context, RouteData data);

@immutable
class AutoRoute {
  final String name;
  final String _path;
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
  })  : _path = path ?? toKababCase(name),
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

  String get path => _path;

  bool get hasSubTree => _children != null;

  RouteCollection? get children => _children;

  bool get isRedirect => redirectTo != null;

  @override
  String toString() {
    return 'RouteConfig{name: $name}';
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
